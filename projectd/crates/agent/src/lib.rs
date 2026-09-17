//! Agent role: worktrees, worker loop, `.context/` sync.
//! Implemented starting at M1. See SPEC.md.

use projectd_protocol as _;

pub fn role_name() -> &'static str {
    "agent"
}
