

GOOD_START_COMMAND_PLAYERS_INPUT = {
  'H1' => {brain: :human, color: :blue},
  'H2' => {brain: :human, color: :red},
  'R3' => {brain: :robot, color: :green},
}

BAD_START_COMMAND_INPUT  = {command: 'StartGame'}
GOOD_START_COMMAND_INPUT = {
  command: 'StartGame',
  players: GOOD_START_COMMAND_PLAYERS_INPUT
}


