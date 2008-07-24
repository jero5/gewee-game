# gewee game
# Copyright (C) 2006  Jeremy Roach
# Licensed under the GNU General Public License version 2

GG_VERSION = '5.0'

LIMIT_STATES = 100

# delete session file if changed
COLUMNS = 13
ROWS = 13
LEVELS = 1

SQUARES = COLUMNS * ROWS * LEVELS

PIECE_PLAYER = 'S'
PIECE_OPPONENT = 'X'
PIECE_EMPTY = '-'

PIECE_STONE = '*'

NORTHWEST_OPPONENT = 1
NORTHEAST_OPPONENT = 2
SOUTHWEST_OPPONENT = 4
SOUTHEAST_OPPONENT = 8
WEST_OPPONENT = 16
EAST_OPPONENT = 32
NORTH_OPPONENT = 64
SOUTH_OPPONENT = 128

NORTHWEST_PLAYER = 256
NORTHEAST_PLAYER = 512
SOUTHWEST_PLAYER = 1024
SOUTHEAST_PLAYER = 2048
WEST_PLAYER = 4096
EAST_PLAYER = 8192
NORTH_PLAYER = 16384
SOUTH_PLAYER = 32768

NORTHWEST_EDGE = 65536
NORTHEAST_EDGE = 131072
SOUTHWEST_EDGE = 262144
SOUTHEAST_EDGE = 524288
WEST_EDGE = 1048576
EAST_EDGE = 2097152
NORTH_EDGE = 4194304
SOUTH_EDGE = 8388608

RANK_HIGHEST = 75

class Session
  attr_reader :board, :score, :opponent_square, 
        :states, :index_state, :gui

  attr_writer :board, :score, :opponent_square, 
        :states, :index_state, :gui

  def initialize()
    @board = ''; @score = 0; @opponent_square = -1
    @states = []; @index_state = -1; @gui = GUI.new
  end
end

class BoardSquare
  attr_reader :flags, :cnt_player, :cnt_opponent, :cnt_corner_player, 
        :cnt_corner_opponent, :cnt_edge, :cnt_corner_edge

  attr_writer :flags, :cnt_player, :cnt_opponent, :cnt_corner_player, 
        :cnt_corner_opponent, :cnt_edge, :cnt_corner_edge

  def initialize()
    @flags = @cnt_player = @cnt_opponent = 0
    @cnt_corner_player = @cnt_corner_opponent = 0
    @cnt_edge = @cnt_corner_edge = 0
  end
end

class GameState
  attr_reader :board, :score, :opponent_square
  attr_writer :board, :score, :opponent_square

  def initialize(board, score, oppo)
    @board = board; @score = score
    @opponent_square = oppo
  end
end

class PieceCount
  attr_reader :player, :opponent, :empty
  attr_writer :player, :opponent, :empty

  def initialize()
    @player = @opponent = @empty = 0
  end
end

class BesiegedGroupEmpties
  attr_reader :empties, :besieged, :nonbesieged
  attr_writer :empties, :besieged, :nonbesieged

  def initialize(empties, besieged)
    @empties = empties
    @besieged = besieged
    @nonbesieged = empties - besieged
  end
end

class GUI
  attr_reader :buttons, :label_score, :label_cnt_player, :label_cnt_opponent,
        :button_previous, :button_next, :button_undo

  attr_writer :buttons, :label_score, :label_cnt_player, :label_cnt_opponent,
        :button_previous, :button_next, :button_undo

  def initialize()
    @buttons = []
  end
end

class Fixnum; def piece; self.chr; end; end

def double_plus_signs(str)
  str.gsub('+') { '++' }
end

def undouble_plus_signs(str)
  str.gsub('++') { '+' }
end

def column_number_to_letter(x)
  (x + 65).chr       # 0 to A, 1 to B, ...
end

def seed_gewee()
  PIECE_EMPTY * SQUARES
end

def valid_point(point)
  if (point < 0 or point >= SQUARES)
    false
  else
    true
  end
end

def near_square(point0, point1)
  (x,y,z) = to_xyz(point0)
  (xx,yy,zz) = to_xyz(point1)
  if ((x - xx).abs <= 1 and (y - yy).abs <= 1 and (z - zz).abs <= 1)
    true
  else
    false
  end
end

def near_square_bonus(point0, point1)
  if (near_square(point0, point1))
    1
  else
    0
  end
end

def almost_near_edge(point)
  (x,y,z) = to_xyz(point)
  if ((x - 1 == 0 or x + 2 == COLUMNS) and
      y != 0 and y + 1 != ROWS)
    true
  elsif ((y - 1 == 0 or y + 2 == ROWS) and
      x != 0 and x + 1 != COLUMNS)
    true
  else
    false
  end
end

def near_edge(point)
  (x,y,z) = to_xyz(point)
  if (x == 0 or x + 1 == COLUMNS or
      y == 0 or y + 1 == ROWS)
    true
  else
    false
  end
end

def gewee_board(session)
  begin
    board = seed_gewee
    score = session.score

    for i in 0..(score < 0 ? 0 : score / 5)
      opponent_move(board, -1)
    end

    board

  rescue Exception => errmsg
    puts "error: gewee_board: #{errmsg}"
    seed_gewee
  end
end

def play_gewee(session, point)
  begin
    to_latest_state(session)
    turns = ['player','opponent']
    board = session.board.dup
    score = session.score

    for turn in turns

      if (turn == 'player')

        if (board[point].piece != PIECE_EMPTY)
          return
        end

        board[point] = PIECE_PLAYER
        remove_surrounded_pieces(board, PIECE_OPPONENT, point)

        if (surrounded_group(board, point))
          return
        end

      elsif (turn == 'opponent')

        if (opponent_forfeits(board))
          oppo = -1
        else
          oppo = opponent_move(board, point)
        end

        if (valid_point(oppo))
          remove_surrounded_pieces(board, PIECE_PLAYER, oppo)
        else
          cnt_piece = count_pieces(board)

          if (cnt_piece.player > cnt_piece.opponent)
            score += 1
          elsif (cnt_piece.player < cnt_piece.opponent)
            score -= 1
          end

          session.score = score          
          session.board = gewee_board(session)
          session.opponent_square = oppo
          session.states << GameState.new(session.board, score, oppo)
          session.index_state = session.states.length - 1

          save_session_info(session)
          return
        end
      end
    end

    session.board = board
    session.score = score
    session.opponent_square = oppo
    session.states << GameState.new(board, score, oppo)
    session.index_state = session.states.length - 1

  rescue Exception => errmsg
    puts "error: play_gewee: #{errmsg}"
  end
end

def opponent_forfeits(board)

  cnt_piece = count_pieces(board)

  if (cnt_piece.player.to_f / SQUARES.to_f * 100.0 >= 35 and
      cnt_piece.opponent.to_f / SQUARES.to_f * 100.0 <= 25)
    return true
  end

  false
end

def count_largest_removed_group(board_before, board_after, piece, point)

  largest_num_pieces = 0

  adjacent_squares(board_before, piece, point) do |s|
    if (board_after[s].piece != piece)
      cnt = count_group(board_before, s)
      if (cnt > largest_num_pieces)
        largest_num_pieces = cnt
      end
    end
    false
  end

  largest_num_pieces
end

def distinct_groups(board, piece, point)

  # are there at least two separate groups of the same kind adjacent to this square?

  squares = []
  adjacent_squares(board, piece, point) do |s|
    if (squares.length == 0)
      squares = group_squares(board, s)
    elsif (!squares.include? s)
      return true
    end
    false
  end

  false
end

def excessive_group(board, visited, max_pieces, point)

  if (visited.length == max_pieces)
    return true
  end

  piece = board[point].piece
  board[point] = PIECE_STONE
  visited << point
  neighbors = [west_square(point), east_square(point),
                north_square(point), south_square(point)]

  for neighbor in neighbors

    if (valid_point(neighbor) and board[neighbor].piece == piece and
          excessive_group(board, visited, max_pieces, neighbor))
      return true
    end
  end

  false
end

def excessive_group_empties(board, visited, empties, max_empties, point)

  piece = board[point].piece
  board[point] = PIECE_STONE
  visited << point
  neighbors = [west_square(point), east_square(point),
                north_square(point), south_square(point)]

  for neighbor in neighbors

    if (valid_point(neighbor))

      if (board[neighbor].piece == PIECE_EMPTY)

        if (empties.length == max_empties)
          return true
        end
        board[neighbor] = PIECE_STONE
        empties << neighbor

      elsif (board[neighbor].piece == piece and
              excessive_group_empties(board, visited, empties, max_empties, neighbor))
        return true
      end
    end
  end

  false
end

def doomed_group(board, turn, point)

  # the board and turn may change, but the point will remain the same

  if (board[point].piece == PIECE_PLAYER)       # prey
    piece_trapper = PIECE_OPPONENT
  elsif (board[point].piece == PIECE_OPPONENT)  # prey
    piece_trapper = PIECE_PLAYER
  end

  if (turn == 'player')
    piece_play = PIECE_PLAYER
    piece_remove = PIECE_OPPONENT
    turn_next = 'opponent'
  elsif (turn == 'opponent')
    piece_play = PIECE_OPPONENT
    piece_remove = PIECE_PLAYER
    turn_next = 'player'
  end

  empties = group_empty_squares(board, point)

  if (empties.length >= 3)
    return false
  end

  for emti in empties
    board_tmp = board.dup
    board_tmp[emti] = piece_play
    remove_surrounded_pieces(board_tmp, piece_remove, emti)

    if (board_tmp[point].piece != PIECE_EMPTY)

      if (piece_play == piece_trapper and threatened_group(board_tmp, emti))
        return false
      elsif (piece_play == board_tmp[point].piece and !threatened_group(board_tmp, point))
        adjacent_squares(board_tmp, piece_trapper, emti) do |trap|
          if (threatened_group(board_tmp, trap))
            return false
          end
          false
        end
      end

      if (!doomed_group(board_tmp, turn_next, point))
        return false
      end
    end
  end

  true
end

def count_besieged_group_empties(board, point)

  empties = group_empty_squares(board, point)

  cnt = 0
  for emti in empties
    empty = describe_square(board, emti)
    if (board[point].piece == PIECE_PLAYER and empty.cnt_opponent > 0)
      cnt += 1
    elsif (board[point].piece == PIECE_OPPONENT and empty.cnt_player > 0)
      cnt += 1
    end
  end

  BesiegedGroupEmpties.new(empties.length, cnt)
end

def group_squares(board, point)
  visited = []
  excessive_group(board.dup, visited, SQUARES, point)
  visited
end

def group_empty_squares(board, point)
  empties = []
  excessive_group_empties(board.dup, [], empties, SQUARES, point)
  empties
end

def count_group(board, point)
  group_squares(board, point).length
end

def count_group_empties(board, point)
  group_empty_squares(board, point).length
end

def surrounded_group(board, point)
  !excessive_group_empties(board.dup, [], [], 0, point)
end

def threatened_group(board, point)
  !excessive_group_empties(board.dup, [], [], 1, point)
end

def threatened_groups_squares(board, piece)

  squares = []
  allvisited = []

  for point in 0...SQUARES

    if (board[point].piece == piece and !allvisited.include? point)

      visited = []

      if (!excessive_group_empties(board.dup, visited, [], 1, point))
        squares << point
      end

      allvisited << visited
    end
  end

  squares
end

def describe_square(board, point)

  square = BoardSquare.new

  west = west_square(point)
  east = east_square(point)
  north = north_square(point)
  south = south_square(point)
  northwest = northwest_square(point)
  northeast = northeast_square(point)
  southwest = southwest_square(point)
  southeast = southeast_square(point)

  if (valid_point(west))
    if (board[west].piece == PIECE_PLAYER)
      square.cnt_player += 1
      square.flags |= WEST_PLAYER
    elsif (board[west].piece == PIECE_OPPONENT)
      square.cnt_opponent += 1
      square.flags |= WEST_OPPONENT
    end
  else
    square.cnt_edge += 1
    square.flags |= WEST_EDGE
  end

  if (valid_point(east))
    if (board[east].piece == PIECE_PLAYER)
      square.cnt_player += 1
      square.flags |= EAST_PLAYER
    elsif (board[east].piece == PIECE_OPPONENT)
      square.cnt_opponent += 1
      square.flags |= EAST_OPPONENT
    end
  else
    square.cnt_edge += 1
    square.flags |= EAST_EDGE
  end

  if (valid_point(north))
    if (board[north].piece == PIECE_PLAYER)
      square.cnt_player += 1
      square.flags |= NORTH_PLAYER
    elsif (board[north].piece == PIECE_OPPONENT)
      square.cnt_opponent += 1
      square.flags |= NORTH_OPPONENT
    end
  else
    square.cnt_edge += 1
    square.flags |= NORTH_EDGE
  end

  if (valid_point(south))
    if (board[south].piece == PIECE_PLAYER)
      square.cnt_player += 1
      square.flags |= SOUTH_PLAYER
    elsif (board[south].piece == PIECE_OPPONENT)
      square.cnt_opponent += 1
      square.flags |= SOUTH_OPPONENT
    end
  else
    square.cnt_edge += 1
    square.flags |= SOUTH_EDGE
  end

  if (valid_point(northwest))
    if (board[northwest].piece == PIECE_PLAYER)
      square.cnt_corner_player += 1
      square.flags |= NORTHWEST_PLAYER
    elsif (board[northwest].piece == PIECE_OPPONENT)
      square.cnt_corner_opponent += 1
      square.flags |= NORTHWEST_OPPONENT
    end
  else
    square.cnt_corner_edge += 1
    square.flags |= NORTHWEST_EDGE
  end

  if (valid_point(northeast))
    if (board[northeast].piece == PIECE_PLAYER)
      square.cnt_corner_player += 1
      square.flags |= NORTHEAST_PLAYER
    elsif (board[northeast].piece == PIECE_OPPONENT)
      square.cnt_corner_opponent += 1
      square.flags |= NORTHEAST_OPPONENT
    end
  else
    square.cnt_corner_edge += 1
    square.flags |= NORTHEAST_EDGE
  end

  if (valid_point(southwest))
    if (board[southwest].piece == PIECE_PLAYER)
      square.cnt_corner_player += 1
      square.flags |= SOUTHWEST_PLAYER
    elsif (board[southwest].piece == PIECE_OPPONENT)
      square.cnt_corner_opponent += 1
      square.flags |= SOUTHWEST_OPPONENT
    end
  else
    square.cnt_corner_edge += 1
    square.flags |= SOUTHWEST_EDGE
  end
  
  if (valid_point(southeast))
    if (board[southeast].piece == PIECE_PLAYER)
      square.cnt_corner_player += 1
      square.flags |= SOUTHEAST_PLAYER
    elsif (board[southeast].piece == PIECE_OPPONENT)
      square.cnt_corner_opponent += 1
      square.flags |= SOUTHEAST_OPPONENT
    end
  else
    square.cnt_corner_edge += 1
    square.flags |= SOUTHEAST_EDGE
  end
  
  square
end

def count_pieces(board)

  cnt = PieceCount.new

  for point in 0...SQUARES

    if (board[point].piece == PIECE_PLAYER)
      cnt.player += 1
    elsif (board[point].piece == PIECE_OPPONENT)
      cnt.opponent += 1
    else
      cnt.empty += 1
    end
  end

  cnt
end

def adjacent_squares(board, piece, point)

  done = false
  neighbors = [west_square(point), east_square(point),
                north_square(point), south_square(point)]

  for neighbor in neighbors
    if (valid_point(neighbor) and board[neighbor].piece == piece)
      done = yield(neighbor)
      break if done
    end
  end
end

def corner_squares(board, piece, point)

  done = false
  neighbors = [northwest_square(point), northeast_square(point),
                southwest_square(point), southeast_square(point)]

  for neighbor in neighbors
    if (valid_point(neighbor) and board[neighbor].piece == piece)
      done = yield(neighbor)
      break if done
    end
  end
end

def near_squares(board, piece, point, &block)
  adjacent_squares(board, piece, point, &block)
  corner_squares(board, piece, point, &block)
end

def remove_surrounded_pieces(board, piece, point)
  begin
    altered = false

    adjacent_squares(board, piece, point) do |s|
      if (surrounded_group(board, s))
        remove_group(board, s)
        altered = true
      end
      false
    end

    altered

  rescue Exception => errmsg
    puts "error: remove_surrounded_pieces: #{errmsg}"
  end
end

def remove_group(board, point)

  piece = board[point].piece
  board[point] = PIECE_EMPTY
  neighbors = [west_square(point), east_square(point),
                north_square(point), south_square(point)]

  for neighbor in neighbors
    if (valid_point(neighbor) and board[neighbor].piece == piece)
      remove_group(board, neighbor)
    end
  end
end

def to_xyz(point)
  (x,r) = point.divmod(ROWS * LEVELS)
  (y,z) = r.divmod(LEVELS)
  [x,y,z]
end

def from_xyz(x,y,z)
  (x * ROWS * LEVELS) + (y * LEVELS) + z
end

def west_square(point)
  (x,y,z) = to_xyz(point)
  if (x - 1 < 0)
    -1
  else
    from_xyz(x - 1,y,z)
  end
end

def east_square(point)
  (x,y,z) = to_xyz(point)
  if (x + 1 >= COLUMNS)
    -1
  else
    from_xyz(x + 1,y,z)
  end
end

def north_square(point)
  (x,y,z) = to_xyz(point)
  if (y - 1 < 0)
    -1
  else
    from_xyz(x,y - 1,z)
  end
end

def south_square(point)
  (x,y,z) = to_xyz(point)
  if (y + 1 >= ROWS)
    -1
  else
    from_xyz(x,y + 1,z)
  end
end

def northwest_square(point)
  (x,y,z) = to_xyz(point)
  if (x - 1 < 0 or y - 1 < 0)
    -1
  else
    from_xyz(x - 1,y - 1,z)
  end
end

def northeast_square(point)
  (x,y,z) = to_xyz(point)
  if (x + 1 >= COLUMNS or y - 1 < 0)
    -1
  else
    from_xyz(x + 1,y - 1,z)
  end
end

def southwest_square(point)
  (x,y,z) = to_xyz(point)
  if (x - 1 < 0 or y + 1 >= ROWS)
    -1
  else
    from_xyz(x - 1,y + 1,z)
  end
end

def southeast_square(point)
  (x,y,z) = to_xyz(point)
  if (x + 1 >= COLUMNS or y + 1 >= ROWS)
    -1
  else
    from_xyz(x + 1,y + 1,z)
  end
end

def undo_state(session)
  if (session.states.length >= 2)
    if (session.index_state == session.states.length - 1)
      session.states.pop
      session.board = session.states[-1].board
      session.score = session.states[-1].score
      session.opponent_square = session.states[-1].opponent_square
      session.index_state = session.states.length - 1
    else
      session.states = session.states[0..session.index_state]
    end
  end
end

def to_previous_state(session)
  if (session.index_state > 0)
    session.index_state -= 1
    session.board = session.states[session.index_state].board
    session.score = session.states[session.index_state].score
    session.opponent_square = session.states[session.index_state].opponent_square
  end
end

def to_next_state(session)
  if (session.index_state < session.states.length - 1)
    session.index_state += 1
    session.board = session.states[session.index_state].board
    session.score = session.states[session.index_state].score
    session.opponent_square = session.states[session.index_state].opponent_square
  end
end

def to_latest_state(session)
  if (session.states.length > 0)
    session.board = session.states[-1].board
    session.score = session.states[-1].score
    session.opponent_square = session.states[-1].opponent_square
    session.index_state = session.states.length - 1
  end
end

def forfeit_game(session)
  session.score -= 1
  session.board = gewee_board(session)
  session.opponent_square = -1
  session.states << GameState.new(session.board, session.score, -1)
  session.index_state = session.states.length - 1
  save_session_info(session)
end

def parse_session(str)

  states = []
  num_game_state_elements = 3
  rows = str.split(/ \n \+ \n /x)

  for i in 0...rows.length
    fields = rows[i].split(/ \, \+ \, /x)

    for k in 0...num_game_state_elements
      fields[k] = fields[k] == nil ? '' : undouble_plus_signs(fields[k])
    end

    # opponent square
    fields[2] = fields[2] == '' ? -1 : fields[2].to_i

    states << GameState.new(fields[0], fields[1].to_i, fields[2])
  end

  if (states.length == 0)
    return nil
  end

  states
end

def read_session()
  begin
    f = File.open("#{$path}session.txt",'r')
    str = f.read
    f.close
    str
  rescue Exception
    ''
  end
end

def get_session_info()
  begin
    session = Session.new
    session.board = gewee_board(session)
    session.states << GameState.new(session.board, 0, -1)
    session.index_state = 0

    str = read_session

    states = parse_session(str)
    if (states)
      session.board = states[-1].board
      session.score = states[-1].score
      session.opponent_square = states[-1].opponent_square
      session.states = states
      session.index_state = states.length - 1
    end

    session

  rescue Exception => errmsg
    puts "error: get_session_info: #{errmsg}"
    session
  end
end

def serialize_session(session)
  str = ''
  for i in 0...session.states.length
    str << 
        double_plus_signs(session.states[i].board) + 
        ",+," + 
        double_plus_signs(session.states[i].score.to_s) + 
        ",+," + 
        double_plus_signs(session.states[i].opponent_square.to_s) + 
        "\n+\n"
  end
  str
end

def save_session_info(session)
  begin
    if (session.states.length > LIMIT_STATES)
      session.states = session.states[-LIMIT_STATES..-1]
      to_latest_state(session)
    end

    str = serialize_session(session)

    f = File.open("#{$path}session.txt",'w')
    f.write(str)
    f.close

  rescue Exception => errmsg
    puts "error: save_session_info: #{errmsg}"
  end
end

def set_gewee(session)

  oppo = session.opponent_square
  board = session.board

  for point in 0...SQUARES

    if (board[point].piece == PIECE_OPPONENT)

      if (point == oppo)
        path = "#{$path}opponent_highlight.png"
      else
        path = "#{$path}opponent.png"
      end

      img_opponent = Gtk::Image.new(path)
      session.gui.buttons[point].image = img_opponent

    elsif (board[point].piece == PIECE_PLAYER)
      img_player = Gtk::Image.new("#{$path}player.png")
      session.gui.buttons[point].image = img_player

    else
      img_empty = Gtk::Image.new("#{$path}empty.png")
      session.gui.buttons[point].image = img_empty
    end
  end

  cnt_piece = count_pieces(board)

  session.gui.label_score.text = "#{session.score}"
  session.gui.label_cnt_player.text = "#{cnt_piece.player}  #{PIECE_PLAYER}"
  session.gui.label_cnt_opponent.text = "#{cnt_piece.opponent}  #{PIECE_OPPONENT}"

  session.gui.button_previous.sensitive = session.index_state > 0 ? true : false
  session.gui.button_next.sensitive = session.index_state < session.states.length - 1 ? true : false
  session.gui.button_undo.sensitive = session.states.length >= 2 ? true : false
end

def build_gewee(session)
  begin
    box = Gtk::HBox.new(false,10)
    grid = Gtk::Table.new(COLUMNS + 1,ROWS + 1,true)
    tasks = Gtk::VBox.new(false,5)

    button = Gtk::Button.new
    button.relief = Gtk::RELIEF_NONE
    button.focus_on_click = false
    grid.attach_defaults(button,0,1,0,1)

    for x in 0...COLUMNS
      label = Gtk::Label.new(column_number_to_letter(x))
      grid.attach_defaults(label,x + 1,x + 2,0,1)
    end

    for x in 0..COLUMNS - COLUMNS
      for y in 0...ROWS

        label = Gtk::Label.new((y + 1).to_s)
        grid.attach_defaults(label,x,x + 1,y + 1,y + 2)
      end
    end

    for point in 0...SQUARES
      (x,y,z) = to_xyz(point)

      button = Gtk::Button.new

      button.signal_connect("clicked", point) { |button, point|
        play_gewee(session, point)
        set_gewee(session)
      }
      button.focus_on_click = false

      session.gui.buttons[point] = button

      grid.attach_defaults(button,x + 1,x + 2,y + 1,y + 2)
    end

    button_undo = Gtk::Button.new("undo")
    button_undo.focus_on_click = false

    button_undo.signal_connect("clicked") {
      undo_state(session)
      set_gewee(session)
    }

    button_forfeit = Gtk::Button.new("forfeit")
    button_forfeit.focus_on_click = false

    button_forfeit.signal_connect("clicked") {
      forfeit_game(session)
      set_gewee(session)
    }

    button_previous = Gtk::Button.new("prev")
    button_previous.focus_on_click = false

    button_previous.signal_connect("clicked") {
      to_previous_state(session)
      set_gewee(session)
    }

    button_next = Gtk::Button.new("next")
    button_next.focus_on_click = false

    button_next.signal_connect("clicked") {
      to_next_state(session)
      set_gewee(session)
    }

    session.gui.button_previous = button_previous
    session.gui.button_next = button_next
    session.gui.button_undo = button_undo

    label_score = Gtk::Label.new
    label_cnt_player = Gtk::Label.new
    label_cnt_opponent = Gtk::Label.new

    session.gui.label_score = label_score
    session.gui.label_cnt_player = label_cnt_player
    session.gui.label_cnt_opponent = label_cnt_opponent

    tasks.pack_start(label_score,false,false,40)
    tasks.pack_start(button_previous,false,false)
    tasks.pack_start(button_next,false,false)
    tasks.pack_start(button_undo,false,false,15)
    tasks.pack_start(button_forfeit,false,false,15)
    tasks.pack_start(label_cnt_player,false,false)
    tasks.pack_start(label_cnt_opponent,false,false)

    box.pack_start(grid)
    box.pack_start(tasks)
    box

  rescue Exception => errmsg
    puts "error: build_gewee: #{errmsg}"
  end
end

def get_self_dir()
  File.dirname(__FILE__) + '/'
end

def main()
  begin
    Gtk.init

    session = get_session_info

    window = Gtk::Window.new("gewee game #{GG_VERSION}")

    window.signal_connect("destroy") {
      save_session_info(session)
      Gtk.main_quit
    }

    box = build_gewee(session)
    set_gewee(session)

    window.add(box)
    window.show_all

    Gtk.main

  rescue Exception => errmsg
    puts "error: main: #{errmsg}"
  end
end

begin
  $path = get_self_dir

  require 'gtk2'
  load "#{$path}monstrosity.rb"

  main

rescue Exception => errmsg
  puts "error: begin: #{errmsg}"
end
