#[starknet::contract]
pub mod MockContract {
    use crate::components::voting::VotingComponent;

    component!(path: VotingComponent, storage: voting, event: VotingEvent);

    #[abi(embed_v0)]
    pub impl VotingImpl = VotingComponent::VotingImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        voting: VotingComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        VotingEvent: VotingComponent::Event,
    }
}
