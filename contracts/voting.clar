;; Voting Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-voted (err u103))

;; Data Maps
(define-map votes
  { project-id: uint, milestone-id: uint, voter: principal }
  { vote: bool }
)

(define-map vote-tallies
  { project-id: uint, milestone-id: uint }
  { yes-votes: uint, no-votes: uint }
)

;; Public Functions
(define-public (vote-on-milestone (project-id uint) (milestone-id uint) (vote bool))
  (let
    (
      (current-tally (default-to { yes-votes: u0, no-votes: u0 } (map-get? vote-tallies { project-id: project-id, milestone-id: milestone-id })))
    )
    (asserts! (is-none (map-get? votes { project-id: project-id, milestone-id: milestone-id, voter: tx-sender })) err-already-voted)
    (map-set votes
      { project-id: project-id, milestone-id: milestone-id, voter: tx-sender }
      { vote: vote }
    )
    (map-set vote-tallies
      { project-id: project-id, milestone-id: milestone-id }
      (merge current-tally
        (if vote
          { yes-votes: (+ (get yes-votes current-tally) u1), no-votes: (get no-votes current-tally) }
          { yes-votes: (get yes-votes current-tally), no-votes: (+ (get no-votes current-tally) u1) }
        )
      )
    )
    (ok true)
  )
)

(define-read-only (get-vote-tally (project-id uint) (milestone-id uint))
  (ok (default-to { yes-votes: u0, no-votes: u0 } (map-get? vote-tallies { project-id: project-id, milestone-id: milestone-id })))
)

(define-read-only (get-user-vote (project-id uint) (milestone-id uint) (voter principal))
  (ok (get vote (default-to { vote: false } (map-get? votes { project-id: project-id, milestone-id: milestone-id, voter: voter }))))
)

