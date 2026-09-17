//! Control role: SQLite, coordinator loop, dispatch, JSON-RPC server.
//! Implemented starting at M0. See SPEC.md.

use projectd_protocol as _;

pub fn role_name() -> &'static str {
    "control"
}
