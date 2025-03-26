#[starknet::component]
pub mod VotingComponent {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
    use crate::interfaces::voting::{DEFAULT_THRESHOLD, IVote, Poll, PollStatus, Voted};

    #[storage]
    pub struct Storage {
        polls: Map<u256, Poll>,
        voters: Map<(ContractAddress, u256), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Voted: Voted,
    }

    #[embeddable_as(VotingImpl)]
    pub impl Voting<
        TContractState, +HasComponent<TContractState>,
    > of IVote<ComponentState<TContractState>> {
        fn create_poll(ref self: ComponentState<TContractState>, name: ByteArray, desc: ByteArray) -> u256 {
            0
        }
        fn vote(ref self: ComponentState<TContractState>, support: bool) {}
        fn resolve_poll(ref self: ComponentState<TContractState>, id: u256) {}
        fn get_poll(self: @ComponentState<TContractState>, id: u256) {}
    }
}
