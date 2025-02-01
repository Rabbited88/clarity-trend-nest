;; TrendNest Contract
;; Manages virtual fashion and AR try-on functionality

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-item (err u103))

;; Data Variables 
(define-data-var last-item-id uint u0)
(define-data-var last-outfit-id uint u0)

;; Data Maps
(define-map virtual-items 
    uint 
    {
        owner: principal,
        name: (string-ascii 50),
        category: (string-ascii 20),
        metadata-uri: (string-utf8 256)
    }
)

(define-map outfits
    uint
    {
        creator: principal,
        items: (list 10 uint),
        likes: uint,
        shares: uint
    }
)

(define-map user-wardrobes
    principal
    (list 100 uint)
)

;; NFT Management
(define-public (mint-virtual-item (name (string-ascii 50)) (category (string-ascii 20)) (metadata-uri (string-utf8 256)))
    (let
        (
            (new-id (+ (var-get last-item-id) u1))
        )
        (try! (nft-mint? virtual-items new-id tx-sender))
        (map-set virtual-items new-id {
            owner: tx-sender,
            name: name,
            category: category,
            metadata-uri: metadata-uri
        })
        (add-to-wardrobe tx-sender new-id)
        (var-set last-item-id new-id)
        (ok new-id)
    )
)

;; Wardrobe Management
(define-public (add-to-wardrobe (user principal) (item-id uint))
    (let
        (
            (current-wardrobe (default-to (list) (map-get? user-wardrobes user)))
            (item (map-get? virtual-items item-id))
        )
        (asserts! (is-some item) err-invalid-item)
        (map-set user-wardrobes user (append current-wardrobe item-id))
        (ok true)
    )
)

;; Outfit Management
(define-public (create-outfit (item-ids (list 10 uint)))
    (let
        (
            (new-id (+ (var-get last-outfit-id) u1))
        )
        ;; Verify all items exist
        (asserts! (fold check-items item-ids true) err-invalid-item)
        (map-set outfits new-id {
            creator: tx-sender,
            items: item-ids,
            likes: u0,
            shares: u0
        })
        (var-set last-outfit-id new-id)
        (ok new-id)
    )
)

(define-private (check-items (item-id uint) (valid bool))
    (and valid (is-some (map-get? virtual-items item-id)))
)

;; Social Features
(define-public (like-outfit (outfit-id uint))
    (let
        (
            (outfit (unwrap! (map-get? outfits outfit-id) err-not-found))
        )
        (map-set outfits outfit-id (merge outfit {likes: (+ (get likes outfit) u1)}))
        (ok true)
    )
)

(define-public (share-outfit (outfit-id uint))
    (let
        (
            (outfit (unwrap! (map-get? outfits outfit-id) err-not-found))
        )
        (map-set outfits outfit-id (merge outfit {shares: (+ (get shares outfit) u1)}))
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-item-details (item-id uint))
    (map-get? virtual-items item-id)
)

(define-read-only (get-outfit-details (outfit-id uint))
    (map-get? outfits outfit-id)
)

(define-read-only (get-user-wardrobe (user principal))
    (map-get? user-wardrobes user)
)
