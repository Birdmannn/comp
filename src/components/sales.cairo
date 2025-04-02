#[starknet::storage]
struct Storage {
    sales: LegacyMap<u256, SalesTerm>,
}

#[derive(Drop, Serde, Copy)]
enum SalesTerm {
    Bought: (),
    Sold: (),
    None: (),  // Default state
}

#[starknet::contract]
mod sales {
    use super::SalesTerm;

    #[external(v0)]
    fn buy(ref self, item_id: u256) {
        self.sales.write(item_id, SalesTerm::Bought);
    }

    #[external(v0)]
    fn sell(ref self, item_id: u256) {
        self.sales.write(item_id, SalesTerm::Sold);
    }
}
