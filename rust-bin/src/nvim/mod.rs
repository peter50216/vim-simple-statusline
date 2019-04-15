use futures::Future;
use log::error;
use rmp_rpc::Endpoint;

pub mod asyncio;
pub mod request_handler;

pub fn run(client: request_handler::RequestHandler) {
    let io = asyncio::stdio();
    let endpoint = Endpoint::new(io, client).map_err(|e| error!("error: {}", e));
    tokio::run(endpoint);
}
