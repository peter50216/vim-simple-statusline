use fern::colors::{Color, ColoredLevelConfig};
use futures::future;
use log::info;
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

struct Test1 {}
impl FunctionHandler for Test1 {
    fn name(&self) -> &str {
        "Test1"
    }
    fn is_sync(&self) -> bool {
        true
    }
    fn handle(&mut self, client: &mut Client, args: &[Value]) -> RequestFuture {
        Box::new(future::ok(
            format!("called withargument length = {}", args.len()).into(),
        ))
    }
}

fn main() {
    setup_logger().unwrap();
    info!("Started.");
    let mut client = RequestHandler::new();
    client.register_function(Box::new(Test1 {}));
    nvim::run(client);
    info!("Done.");
}
