# README

This repository contains a work-in-progress implementation of the ["Build a Friend.tech Clone"](https://docs.hiro.so/hacks/build-a-friend-tech-clone#challenges) challenge for the [Hiro Hacks] series.

This project is intended to be a clone of https://friend.tech and its [contracts](https://basescan.org/address/0xcf205808ed36593aa40a44f10c7f7c2f67d4a4d4#code).

## Getting Started

To get the application running, follow these steps:

1. Clone the repository: `git clone https://github.com/nochiel/hiro-hacks-template.git`
2. Navigate into the directory: `cd hiro-hacks-template`
3. Install the dependencies: `pnpm install`
4. Start the development server: `pnpm dev`

To test the contracts, use `clarinet console`.

## Roadmap

> The deadline to submit is Wednesday, December 6th at midnight ET.

Unfortunately t I saw the challenges late and so, embarrassingly, I've only had a day to work on this before the deadline.

The challenges to be done are:

- [x] Balance and Supply Query Functions.
- [x] Price Query Functions
- [x] Fee Management
- [x] Access Control
- [ ] UI Integration
  - [ ] List accounts with their data:
    - avatar (profile picture)
    - keys supply
    - key balance
    - holders
    - holdings
  - [ ] Social media functions
    - [ ] Posts
    - [ ] Direct messages
    - [ ] Voting to boost messages (voting power is based on number of keys held.)
    - [ ] Private chat rooms for holders of keys.
- [ ] Message Signature

Side quests:

- [ ] Write a test suite for the contracts.
- [ ] An exchange UI for trading keys. (Refer to https://friendmex.com/ for a great example.)
