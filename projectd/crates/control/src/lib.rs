//! Control role: SQLite, coordinator loop, dispatch, JSON-RPC server.

pub mod client;
mod db;
mod id;
pub mod paths;
pub mod provider;
pub mod rpc;

pub use provider::{load_default, stub_provider, Provider};
pub use rpc::{serve, ControlConfig};

pub fn role_name() -> &'static str {
    "control"
}
