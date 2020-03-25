use fern::colors::{Color, ColoredLevelConfig};
use futures::future::{self, Future};
use log::info;
use rmp::decode;
use rmp_rpc::{Client, Value};
use vim_statusline::nvim::{
    self,
    request_handler::{FunctionHandler, RequestFuture, RequestHandler},
};

fn setup_logger() -> Result<(), fern::InitError> {
    let colors_line = ColoredLevelConfig::new()
        .error(Color::Red)
        .warn(Color::Yellow);

    fern::Dispatch::new()
        .format(move |out, message, record| {
            out.finish(format_args!(
                "{color_line}{date}[{target} {level}] {message}",
                color_line = format_args!(
                    "\x1B[{}m",
                    colors_line.get_color(&record.level()).to_fg_str()
                ),
                date = chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
                target = record.target(),
                level = record.level(),
                message = message
            ))
        })
        .level(log::LevelFilter::Debug)
        .chain(fern::log_file("/tmp/vim-statusline.log")?)
        .apply()?;
    Ok(())
}

fn unwrap_response(resp: rmp_rpc::Response) -> impl Future<Item = Value, Error = Value> {
    resp.then(|r| match r {
        Err(e) => future::err(format!("error while receiving response: {:?}", e).into()),
        Ok(Err(e)) => future::err(format!("error response: {:?}", e).into()),
        Ok(Ok(res)) => future::ok(res),
    })
}

fn get_buf_number(buf: rmp_rpc::Value) -> u64 {
    decode::read_int(&mut buf.as_ext().unwrap().1).unwrap()
}

struct BuildStatusLineFunc {}
impl FunctionHandler for BuildStatusLineFunc {
    fn name(&self) -> &str {
        "BuildStatusLine"
    }
    fn is_sync(&self) -> bool {
        true
    }
    fn handle(&mut self, client: &mut Client, args: &[Value]) -> RequestFuture {
        Box::new(
            unwrap_response(client.request("nvim_get_current_buf", &[])).map(|buf| {
                let active = get_buf_number(buf);
                format!("%{{SetHighlightGroups({})}}", active).into()
            }),
        )
    }
}

fn main() {
    setup_logger().unwrap();
    info!("Started.");
    let mut client = RequestHandler::new();
    client.register_function(Box::new(BuildStatusLineFunc {}));
    nvim::run(client);
    info!("Done.");
}
