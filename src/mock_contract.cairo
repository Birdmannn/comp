#[starknet::contract]
pub mod MockContract {
    use crate::components::voting::VotingComponent;
    use crate::components::sales::SalesComponent;

    #[abi(embed_v0)]
    pub impl VotingImpl = VotingComponent::VotingImpl<ContractState>;

    #[abi(embed_v0)]
    pub impl SalesImpl = SalesComponent::SalesImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        pub voting: VotingComponent::Storage,
        #[substorage(v0)]
        pub sales: SalesComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        VotingEvent: VotingComponent::Event,

        #[flat]
        SalesEvent: SalesComponent::Event,
    }
    
}