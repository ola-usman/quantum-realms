;; Title: QuantumRealms - Bitcoin-Native Cross-Reality Gaming Protocol
;; Summary: 
;; Revolutionary Bitcoin-secured metaverse enabling seamless NFT asset portability 
;; across infinite gaming dimensions with provable digital ownership and yield generation.
;; Description:
;; QuantumRealms revolutionizes digital gaming by creating the first truly interoperable 
;; metaverse protocol built on Bitcoin's unbreakable security foundation through Stacks L2. 
;; 
;; Our protocol enables players to own, upgrade, and monetize NFT assets that transcend 
;; individual games, creating persistent digital identities with cross-dimensional utility. 
;; Features include evolutionary avatar systems with permanent progression tracking, 
;; Bitcoin-collateralized reward mechanisms, and composable asset architectures that 
;; maintain immutable metadata across unlimited gaming ecosystems.
;; 
;; Built for maximum Bitcoin compliance, Stacks L2 scalability, and true digital sovereignty,
;; QuantumRealms establishes the foundational infrastructure for the next generation of 
;; decentralized gaming experiences where players truly own their digital destinies.

;; ERROR CONSTANTS
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-GAME-ASSET (err u2))
(define-constant ERR-INSUFFICIENT-FUNDS (err u3))
(define-constant ERR-TRANSFER-FAILED (err u4))
(define-constant ERR-LEADERBOARD-FULL (err u5))
(define-constant ERR-ALREADY-REGISTERED (err u6))
(define-constant ERR-INVALID-REWARD (err u7))
(define-constant ERR-INVALID-INPUT (err u8))
(define-constant ERR-INVALID-SCORE (err u9))
(define-constant ERR-INVALID-FEE (err u10))
(define-constant ERR-INVALID-ENTRIES (err u11))
(define-constant ERR-PLAYER-NOT-FOUND (err u12))
(define-constant ERR-INVALID-AVATAR (err u13))
(define-constant ERR-WORLD-NOT-FOUND (err u14))
(define-constant ERR-INVALID-NAME (err u15))
(define-constant ERR-INVALID-DESCRIPTION (err u16))
(define-constant ERR-INVALID-RARITY (err u17))
(define-constant ERR-INVALID-POWER-LEVEL (err u18))
(define-constant ERR-INVALID-ATTRIBUTES (err u19))
(define-constant ERR-INVALID-WORLD-ACCESS (err u20))
(define-constant ERR-INVALID-OWNER (err u21))
(define-constant ERR-MAX-LEVEL-REACHED (err u22))
(define-constant ERR-MAX-EXPERIENCE-REACHED (err u23))
(define-constant ERR-INVALID-LEVEL-UP (err u24))

;; GAME MECHANICS CONSTANTS
(define-constant MAX-LEVEL u100)
(define-constant MAX-EXPERIENCE-PER-LEVEL u1000)
(define-constant BASE-EXPERIENCE-REQUIRED u100)

;; PROTOCOL CONFIGURATION VARIABLES
(define-data-var protocol-fee uint u10)
(define-data-var max-leaderboard-entries uint u50)
(define-data-var total-prize-pool uint u0)
(define-data-var total-assets uint u0)
(define-data-var total-avatars uint u0)
(define-data-var total-worlds uint u0)

;; ACCESS CONTROL MAPS
(define-map protocol-admin-whitelist principal bool)

;; INPUT VALIDATION FUNCTIONS
(define-private (is-valid-name (name (string-ascii 50)))
  (and 
    (>= (len name) u1)
    (<= (len name) u50)
    (not (is-eq name ""))
  )
)

(define-private (is-valid-description (description (string-ascii 200)))
  (and 
    (>= (len description) u1)
    (<= (len description) u200)
    (not (is-eq description ""))
  )
)

(define-private (is-valid-rarity (rarity (string-ascii 20)))
  (or 
    (is-eq rarity "common")
    (is-eq rarity "uncommon")
    (is-eq rarity "rare")
    (is-eq rarity "epic")
    (is-eq rarity "legendary")
  )
)

(define-private (is-valid-power-level (power uint))
  (and (>= power u1) (<= power u1000))
)

(define-private (is-valid-attributes (attributes (list 10 (string-ascii 20))))
  (and 
    (>= (len attributes) u1)
    (<= (len attributes) u10)
  )
)

(define-private (is-valid-world-access (worlds (list 10 uint)))
  (and 
    (>= (len worlds) u1)
    (<= (len worlds) u10)
    (fold check-world-exists worlds true)
  )
)

(define-private (check-world-exists (world-id uint) (valid bool))
  (and valid (is-some (get-world-details world-id)))
)

;; NFT TOKEN DEFINITIONS
(define-non-fungible-token quantum-realms-asset uint)
(define-non-fungible-token quantum-avatar uint)

;; DATA STORAGE MAPS

;; Enhanced Asset Metadata Map
(define-map quantum-asset-metadata 
  { token-id: uint }
  { 
    name: (string-ascii 50),
    description: (string-ascii 200),
    rarity: (string-ascii 20),
    power-level: uint,
    world-id: uint,
    attributes: (list 10 (string-ascii 20)),
    experience: uint,
    level: uint
  }
)

;; Player Avatar Map
(define-map avatar-metadata
  { avatar-id: uint }
  {
    name: (string-ascii 50),
    level: uint,
    experience: uint,
    achievements: (list 20 (string-ascii 50)),
    equipped-assets: (list 5 uint),
    world-access: (list 10 uint)
  }
)

;; Game Worlds Registry
(define-map quantum-worlds
  { world-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    entry-requirement: uint,
    active-players: uint,
    total-rewards: uint
  }
)

;; Leaderboard System
(define-map global-leaderboard 
  { player: principal }
  { 
    score: uint, 
    games-played: uint,
    total-rewards: uint,
    avatar-id: uint,
    rank: uint,
    achievements: (list 20 (string-ascii 50))
  }
)

;; UTILITY & VALIDATION FUNCTIONS
(define-read-only (is-protocol-admin (sender principal))
  (default-to false (map-get? protocol-admin-whitelist sender))
)

(define-read-only (is-valid-principal (input principal))
  (and 
    (not (is-eq input tx-sender))
    (not (is-eq input (as-contract tx-sender)))
  )
)

(define-read-only (is-safe-principal (input principal))
  (and 
    (is-valid-principal input)
    (or 
      (is-protocol-admin input)
      (is-some (map-get? global-leaderboard { player: input }))
    )
  )
)

(define-read-only (get-world-details (world-id uint))
  (map-get? quantum-worlds { world-id: world-id })
)

(define-read-only (get-avatar-details (avatar-id uint))
  (map-get? avatar-metadata { avatar-id: avatar-id })
)

(define-read-only (get-top-players)
  (let 
    (
      (max-entries (var-get max-leaderboard-entries))
    )
    (list 
      tx-sender
    )
  )
)

;; EXPERIENCE & LEVELING READ-ONLY FUNCTIONS

;; Read-only function to get experience required for next level
(define-read-only (get-next-level-requirement (avatar-id uint))
  (match (get-avatar-details avatar-id)
    metadata (ok (calculate-level-up-experience (get level metadata)))
    ERR-INVALID-AVATAR
  )
)

;; Read-only function to check if avatar can receive experience
(define-read-only (can-receive-experience
    (avatar-id uint)
    (experience-amount uint)
  )
  (match (get-avatar-details avatar-id)
    metadata (ok (and
      (< (get level metadata) MAX-LEVEL)
      (validate-experience-gain 
        (get experience metadata)
        experience-amount
        (get level metadata)
      )))
    ERR-INVALID-AVATAR
  )
)

;; PROTOCOL MANAGEMENT FUNCTIONS
(define-public (initialize-protocol 
  (entry-fee uint) 
  (max-entries uint)
)
  (begin
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= entry-fee u1) (<= entry-fee u1000)) ERR-INVALID-FEE)
    (asserts! (and (>= max-entries u1) (<= max-entries u1000)) ERR-INVALID-ENTRIES)
    
    (var-set protocol-fee entry-fee)
    (var-set max-leaderboard-entries max-entries)
    
    (ok true)
  )
)

;; ASSET MANAGEMENT FUNCTIONS
(define-public (mint-quantum-asset 
    (name (string-ascii 50))
    (description (string-ascii 200))
    (rarity (string-ascii 20))
    (power-level uint)
    (world-id uint)
    (attributes (list 10 (string-ascii 20)))
  )
  (let 
    ((token-id (+ (var-get total-assets) u1)))
    
    ;; Input validation
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-name name) ERR-INVALID-NAME)
    (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
    (asserts! (is-valid-rarity rarity) ERR-INVALID-RARITY)
    (asserts! (is-valid-power-level power-level) ERR-INVALID-POWER-LEVEL)
    (asserts! (is-some (get-world-details world-id)) ERR-WORLD-NOT-FOUND)
    (asserts! (is-valid-attributes attributes) ERR-INVALID-ATTRIBUTES)
    
    (try! (nft-mint? quantum-realms-asset token-id tx-sender))
    
    (map-set quantum-asset-metadata 
      { token-id: token-id }
      {
        name: name,
        description: description,
        rarity: rarity,
        power-level: power-level,
        world-id: world-id,
        attributes: attributes,
        experience: u0,
        level: u1
      }
    )
    
    (var-set total-assets token-id)
    (ok token-id)
  )
)

(define-public (transfer-quantum-asset 
  (token-id uint) 
  (recipient principal)
)
  (begin
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? quantum-realms-asset token-id) ERR-INVALID-GAME-ASSET))
      ERR-NOT-AUTHORIZED
    )
    
    (asserts! (is-valid-principal recipient) ERR-INVALID-INPUT)
    
    (nft-transfer? quantum-realms-asset token-id tx-sender recipient)
  )
)

;; AVATAR SYSTEM FUNCTIONS
(define-public (create-quantum-avatar
    (name (string-ascii 50))
    (world-access (list 10 uint))
  )
  (let
    ((avatar-id (+ (var-get total-avatars) u1)))
    
    ;; Input validation
    (asserts! (is-valid-name name) ERR-INVALID-NAME)
    (asserts! (is-valid-world-access world-access) ERR-INVALID-WORLD-ACCESS)
    (asserts! 
      (is-none (map-get? global-leaderboard { player: tx-sender }))
      ERR-ALREADY-REGISTERED
    )
    
    (try! (nft-mint? quantum-avatar avatar-id tx-sender))
    
    (map-set avatar-metadata
      { avatar-id: avatar-id }
      {
        name: name,
        level: u1,
        experience: u0,
        achievements: (list),
        equipped-assets: (list),
        world-access: world-access
      }
    )
    
    (map-set global-leaderboard
      { player: tx-sender }
      {
        score: u0,
        games-played: u0,
        total-rewards: u0,
        avatar-id: avatar-id,
        rank: u0,
        achievements: (list)
      }
    )
    
    (var-set total-avatars avatar-id)
    (ok avatar-id)
  )
)

(define-public (evolve-avatar-experience
    (avatar-id uint)
    (experience-gained uint)
  )
  (let
    (
      ;; Unwrap metadata with safety checks
      (current-metadata (unwrap! (get-avatar-details avatar-id) ERR-INVALID-AVATAR))
      (avatar-owner (unwrap! (nft-get-owner? quantum-avatar avatar-id) ERR-INVALID-AVATAR))
      (current-level (get level current-metadata))
      (current-experience (get experience current-metadata))
    )
    
    ;; Authorization checks
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Avatar validation
    (asserts! (<= avatar-id (var-get total-avatars)) ERR-INVALID-AVATAR)
    
    ;; Experience and level validation
    (asserts! (> experience-gained u0) ERR-INVALID-INPUT)
    (asserts! (< current-level MAX-LEVEL) ERR-MAX-LEVEL-REACHED)
    (asserts! 
      (validate-experience-gain current-experience experience-gained current-level)
      ERR-MAX-EXPERIENCE-REACHED
    )
    
    ;; Calculate new stats
    (let
      (
        (new-experience (+ current-experience experience-gained))
        (should-level-up (can-level-up current-experience experience-gained current-level))
        (new-level (if should-level-up (+ current-level u1) current-level))
      )
      
      ;; Level up validation
      (asserts! 
        (<= new-level MAX-LEVEL)
        ERR-MAX-LEVEL-REACHED
      )
      
      ;; Update avatar metadata
      (map-set avatar-metadata
        { avatar-id: avatar-id }
        (merge current-metadata
          {
            experience: new-experience,
            level: new-level
          }
        )
      )
      
      ;; Return success with level up status
      (ok should-level-up)
    )
  )
)

;; QUANTUM WORLD MANAGEMENT FUNCTIONS
(define-public (create-quantum-world 
    (name (string-ascii 50))
    (description (string-ascii 200))
    (entry-requirement uint)
  )
  (let
    ((world-id (+ (var-get total-worlds) u1)))
    
    ;; Input validation
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-name name) ERR-INVALID-NAME)
    (asserts! (is-valid-description description) ERR-INVALID-DESCRIPTION)
    (asserts! (>= entry-requirement u0) ERR-INVALID-INPUT)
    
    (map-set quantum-worlds
      { world-id: world-id }
      {
        name: name,
        description: description,
        entry-requirement: entry-requirement,
        active-players: u0,
        total-rewards: u0
      }
    )
    
    (var-set total-worlds world-id)
    (ok world-id)
  )
)

;; LEADERBOARD MANAGEMENT FUNCTIONS
(define-public (update-player-achievements 
  (player principal) 
  (new-score uint)
)
  (let 
    (
      (current-stats (unwrap! 
        (map-get? global-leaderboard { player: player }) 
        ERR-PLAYER-NOT-FOUND
      ))
    )
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-principal player) ERR-INVALID-INPUT)
    (asserts! (and (>= new-score u0) (<= new-score u10000)) ERR-INVALID-SCORE)
    
    (map-set global-leaderboard 
      { player: player }
      (merge current-stats 
        {
          score: new-score,
          games-played: (+ (get games-played current-stats) u1)
        }
      )
    )
    
    (ok true)
  )
)

;; BITCOIN REWARD DISTRIBUTION SYSTEM
(define-public (distribute-bitcoin-rewards)
  (let 
    (
      (top-players (get-top-players))
    )
    (asserts! (is-protocol-admin tx-sender) ERR-NOT-AUTHORIZED)
    
    (try! 
      (fold distribute-quantum-reward 
        (filter is-valid-reward-candidate top-players) 
        (ok true)
      )
    )
    
    (ok true)
  )
)

(define-private (is-valid-reward-candidate (player principal))
  (match (map-get? global-leaderboard { player: player })
    stats (and 
            (> (get score stats) u0)
            (is-valid-principal player)
          )
    false
  )
)

(define-private (distribute-quantum-reward 
  (player principal) 
  (previous-result (response bool uint))
)
  (match (map-get? global-leaderboard { player: player })
    player-stats 
      (let 
        (
          (reward-amount (calculate-quantum-reward (get score player-stats)))
        )
        (if (and (is-ok previous-result) (> reward-amount u0))
          (begin
            (map-set global-leaderboard 
              { player: player }
              (merge player-stats 
                { total-rewards: (+ (get total-rewards player-stats) reward-amount) }
              )
            )
            (ok true)
          )
          previous-result
        )
      )
    previous-result
  )
)

(define-private (calculate-quantum-reward (score uint))
  (if (<= score u100)
    u0
    (if (<= score u10000)
      (* score u10)
      u0
    )
  )
)

;; HELPER FUNCTIONS FOR EXPERIENCE & LEVELING

;; Helper function to calculate required experience for next level
(define-private (calculate-level-up-experience (current-level uint))
  (* BASE-EXPERIENCE-REQUIRED current-level)
)

;; Helper function to validate experience points
(define-private (validate-experience-gain
    (current-experience uint)
    (gained-experience uint)
    (current-level uint)
  )
  (let
    (
      (max-allowed-gain (calculate-level-up-experience current-level))
      (new-total-experience (+ current-experience gained-experience))
    )
    (and
      (<= gained-experience max-allowed-gain)
      (<= new-total-experience (* MAX-EXPERIENCE-PER-LEVEL current-level))
      (< current-experience (* MAX-EXPERIENCE-PER-LEVEL current-level))
    )
  )
)

;; Helper function to check if level up is warranted
(define-private (can-level-up
    (current-experience uint)
    (gained-experience uint)
    (current-level uint)
  )
  (let
    (
      (new-total-experience (+ current-experience gained-experience))
      (required-experience (calculate-level-up-experience current-level))
    )
    (>= new-total-experience required-experience)
  )
)

;; PROTOCOL INITIALIZATION
;; Set contract deployer as initial protocol administrator
(map-set protocol-admin-whitelist tx-sender true)