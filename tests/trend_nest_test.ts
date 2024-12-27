import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can mint virtual item",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('trend_nest', 'mint-virtual-item', [
                types.ascii("Blue Jeans"),
                types.ascii("pants"),
                types.utf8("ipfs://QmXyZ123...")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let itemDetails = chain.callReadOnlyFn(
            'trend_nest',
            'get-item-details',
            [types.uint(1)],
            wallet1.address
        );
        
        assertEquals(
            itemDetails.result.expectSome().expectTuple(),
            {
                owner: wallet1.address,
                name: "Blue Jeans",
                category: "pants",
                'metadata-uri': "ipfs://QmXyZ123..."
            }
        );
    }
});

Clarinet.test({
    name: "Can create and interact with outfit",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // First mint some items
        let block = chain.mineBlock([
            Tx.contractCall('trend_nest', 'mint-virtual-item', [
                types.ascii("Item 1"),
                types.ascii("top"),
                types.utf8("ipfs://1")
            ], wallet1.address),
            Tx.contractCall('trend_nest', 'mint-virtual-item', [
                types.ascii("Item 2"),
                types.ascii("bottom"),
                types.utf8("ipfs://2")
            ], wallet1.address)
        ]);
        
        // Create outfit
        let createOutfit = chain.mineBlock([
            Tx.contractCall('trend_nest', 'create-outfit', [
                types.list([types.uint(1), types.uint(2)])
            ], wallet1.address)
        ]);
        
        createOutfit.receipts[0].result.expectOk().expectUint(1);
        
        // Like and share outfit
        let interactions = chain.mineBlock([
            Tx.contractCall('trend_nest', 'like-outfit', [
                types.uint(1)
            ], wallet2.address),
            Tx.contractCall('trend_nest', 'share-outfit', [
                types.uint(1)
            ], wallet2.address)
        ]);
        
        interactions.receipts[0].result.expectOk().expectBool(true);
        interactions.receipts[1].result.expectOk().expectBool(true);
        
        // Check outfit details
        let outfitDetails = chain.callReadOnlyFn(
            'trend_nest',
            'get-outfit-details',
            [types.uint(1)],
            wallet1.address
        );
        
        const outfit = outfitDetails.result.expectSome().expectTuple();
        assertEquals(outfit.likes, types.uint(1));
        assertEquals(outfit.shares, types.uint(1));
    }
});