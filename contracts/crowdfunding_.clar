;; Crowdfunding Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var project-id-nonce uint u0)

;; Data Maps
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-utf8 1000),
    funding-goal: uint,
    funds-raised: uint,
    deadline: uint,
    status: (string-ascii 20)
  }
)

(define-map project-backers
  { project-id: uint, backer: principal }
  { amount: uint }
)

;; Public Functions
(define-public (create-project (title (string-ascii 100)) (description (string-utf8 1000)) (funding-goal uint) (deadline uint))
  (let
    (
      (project-id (var-get project-id-nonce))
    )
    (map-set projects
      { project-id: project-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        funding-goal: funding-goal,
        funds-raised: u0,
        deadline: deadline,
        status: "active"
      }
    )
    (var-set project-id-nonce (+ project-id u1))
    (ok project-id)
  )
)

(define-public (back-project (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
      (current-balance (default-to u0 (get amount (map-get? project-backers { project-id: project-id, backer: tx-sender }))))
    )
    (asserts! (< block-height (get deadline project)) (err u104))
    (asserts! (is-eq (get status project) "active") (err u105))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set projects
      { project-id: project-id }
      (merge project { funds-raised: (+ (get funds-raised project) amount) })
    )
    (map-set project-backers
      { project-id: project-id, backer: tx-sender }
      { amount: (+ current-balance amount) }
    )
    (ok true)
  )
)

(define-read-only (get-project (project-id uint))
  (ok (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
)

(define-read-only (get-backer-contribution (project-id uint) (backer principal))
  (ok (default-to { amount: u0 } (map-get? project-backers { project-id: project-id, backer: backer })))
)

(define-public (update-project-status (project-id uint) (new-status (string-ascii 20)))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
    (ok (map-set projects
      { project-id: project-id }
      (merge project { status: new-status })
    ))
  )
)

