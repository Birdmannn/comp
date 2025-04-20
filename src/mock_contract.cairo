#[starknet::contract]
pub mod MockContract {
    use crate::components::voting::VotingComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::{ContractAddress, ClassHash};

   
    // Component declarations
    component!(path: VotingComponent, storage: voting, event: VotingEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    /// Ownable
    #[abi(embed_v0)]
    impl VotingImpl = VotingComponent::VotingImpl<ContractState>;
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    /// Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;


    // Combine storage from components
    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        voting: VotingComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        // Original storage remains empty as specified
    }

    // Combine events from components
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        VotingEvent: VotingComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    // Constructor to initialize the components
    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress) {
        // Initialize the ownable component with the initial owner
        self.ownable.initializer(initial_owner);
    
        // Initialize the upgradeable component
        // self.upgradeable.initializer();
    }

        
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // This function can only be called by the owner
            self.ownable.assert_only_owner();

            // Replace the class hash upgrading the contract
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}