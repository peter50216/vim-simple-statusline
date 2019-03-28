use futures::{future, Future};
use log::{debug, warn};
use rmp_rpc::{Client, ServiceWithClient, Value};
use std::collections::HashMap;

enum Request<'a> {
    Poll,
    Specs,
    Function(&'a str),
    Autocmd(&'a str, &'a str),
    Command(&'a str),
    Unknown(&'a str),
}

impl<'a> From<&'a str> for Request<'a> {
    fn from(event: &'a str) -> Self {
        if event == "poll" {
            Request::Poll
        } else if event == "specs" {
            Request::Specs
        } else {
            let split: Vec<&str> = event.splitn(3, ":").collect();
            if split.len() < 3 {
                return Request::Unknown(event);
            }
            match split[1] {
                "autocmd" => match split[2].splitn(2, ":").collect::<Vec<&str>>().as_slice() {
                    &[event, pattern] => Request::Autocmd(event, pattern),
                    _ => Request::Unknown(event),
                },
                "function" => Request::Function(split[2]),
                "command" => Request::Command(split[2]),
                _ => Request::Unknown(event),
            }
        }
    }
}

pub type RequestFuture = Box<dyn Future<Item = Value, Error = Value> + Send>;

// \ {'sync': v:true, 'name': 'BuildStatusLine', 'type': 'function', 'opts': {}},
// \ {'sync': v:false, 'name': 'VimEnter,ColorScheme', 'type': 'autocmd', 'opts': {}},
// \ {'sync': v:true, 'name': 'TestCmd1', 'type': 'command', 'opts': {'nargs': 1}},
// \ {'sync': v:true, 'name': 'GetLintStatus', 'type': 'function', 'opts': {}},

// Feels like we can't do better until we have trait fields T_T.
// (https://github.com/nikomatsakis/fields-in-traits-rfc)
// TODO: support other options (range, eval, ...)
pub trait FunctionHandler: Send {
    fn name(&self) -> &str;
    fn is_sync(&self) -> bool;
    fn handle(&mut self, client: &mut Client, args: &[Value]) -> RequestFuture;
}

// TODO: support other options (group, nested, ...)
pub trait AutocmdHandler: Send {
    fn pattern(&self) -> &str;
    fn event(&self) -> &str;
    fn handle(&mut self, client: &mut Client, args: &[Value]);
}

// TODO: support other options (nargs, range, eval, ...)
pub trait CommandHandler: Send {
    fn name(&self) -> &str;
    fn is_sync(&self) -> bool;
    fn handle(&mut self, client: &mut Client, args: &[Value]) -> RequestFuture;
}

trait ToVimDict {
    fn serialize(&self) -> Value;
}

impl ToVimDict for FunctionHandler {
    fn serialize(&self) -> Value {
        vec![
            ("sync".into(), self.is_sync().into()),
            ("name".into(), self.name().into()),
            ("type".into(), "function".into()),
            ("opts".into(), Value::Map(vec![])),
        ]
        .into()
    }
}

pub struct RequestHandler {
    function_map: HashMap<String, Box<dyn FunctionHandler>>,
    command_map: HashMap<String, Box<dyn CommandHandler>>,
    autocmd_map: HashMap<(String, String), Box<dyn AutocmdHandler>>,
}

fn unwrap_arg(args: &[Value]) -> Result<&Vec<Value>, String> {
    args.get(0)
        .and_then(|arg| arg.as_array())
        .ok_or_else(|| "Bad argument".to_string())
}

impl RequestHandler {
    pub fn new() -> Self {
        RequestHandler {
            function_map: HashMap::new(),
            autocmd_map: HashMap::new(),
            command_map: HashMap::new(),
        }
    }

    fn handle_function(
        &mut self,
        client: &mut Client,
        function: &str,
        args: &[Value],
    ) -> RequestFuture {
        unwrap_arg(args)
            .map(|args| {
                match self.function_map.get_mut(function) {
                    Some(func) => func.handle(client, args),
                    None => Box::new(future::err(
                        // TODO: log error?
                        format!("Unknown function: {}", function).into(),
                    )),
                }
            })
            .unwrap_or_else(|e| Box::new(future::err(e.into())))
    }

    fn handle_autocmd(&mut self, client: &mut Client, event: &str, pattern: &str, args: &[Value]) {
        unwrap_arg(args)
            .map(|args| {
                match self
                    .autocmd_map
                    .get_mut(&(event.to_string(), pattern.to_string()))
                {
                    Some(autocmd) => autocmd.handle(client, args),
                    None => warn!("Unknown autocmd: {} {}", event, pattern),
                };
            })
            .unwrap_or_else(|e| warn!("QQ {}", e));
    }

    fn handle_command(
        &mut self,
        client: &mut Client,
        command: &str,
        args: &[Value],
    ) -> RequestFuture {
        unwrap_arg(args)
            .map(|args| match self.command_map.get_mut(command) {
                Some(cmd) => cmd.handle(client, args),
                None => Box::new(future::err(format!("Unknown command: {}", command).into())),
            })
            .unwrap_or_else(|e| Box::new(future::err(e.into())))
    }

    pub fn register_function(&mut self, func: Box<dyn FunctionHandler>) {
        let name = func.name();
        self.function_map.insert(name.to_string(), func);
    }
}

impl ServiceWithClient for RequestHandler {
    type RequestFuture = RequestFuture;

    fn handle_request(
        &mut self,
        client: &mut Client,
        method: &str,
        args: &[Value],
    ) -> RequestFuture {
        debug!("Got request {}, {:?}", method, args);
        let request = Request::from(method);
        match request {
            Request::Poll => Box::new(future::ok("ok".into())),
            Request::Specs => {
                // TODO: really return specs.
                let mut specs: Vec<Value> = vec![];
                specs.extend(self.function_map.values().map(|func| func.serialize()));
                Box::new(future::ok(specs.into()))
            }
            Request::Function(function) => self.handle_function(client, function, args),
            Request::Command(command) => self.handle_command(client, command, args),
            _ => {
                // Autocmd should be notification.
                warn!("Got unknown request: {}", method);
                Box::new(future::err(format!("Unknown method: {}", method).into()))
            }
        }
    }

    // TODO: async command / function seems to be notification.
    fn handle_notification(&mut self, client: &mut Client, method: &str, args: &[Value]) {
        debug!("Got notification {}", method);
        match Request::from(method) {
            Request::Autocmd(event, pattern) => self.handle_autocmd(client, event, pattern, args),
            _ => warn!("Got unknown notification: {}", method),
        }
    }
}
