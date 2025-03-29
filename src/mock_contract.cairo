#[starknet::contract]
pub mod MockContract {
    use crate::components::voting::VotingComponent;

    #[abi(embed_v0)]
    pub impl VotingImpl = VotingComponent::VotingImpl<ContractState>;

    #[storage]
    pub struct Storage {
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        VotingEvent: VotingComponent::Event,
    }

    
}