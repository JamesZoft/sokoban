#!/usr/bin/ruby -w

require 'curses'
require 'matrix'

class Sokoban

  attr_accessor :map_state, :win, :playing, :player_pos

  def play
    init
    playing = true
    while playing
      process_input
      draw_map
    end
  end

  def init
    @map_state = Array.new(11).map! { Array.new(19).map! { ' ' } }
    max_width = 0
    max_height = 0
    cur_line = 0
    cur_col = 0
    File.open 'maps/level_1.map', 'r' do |infile|
      while (line = infile.gets)
        max_width = line.to_s.length > max_width ? line.to_s.length : max_width
        max_height = line.to_s.length > max_height ? line.to_s.length : max_height
        line.chomp.chars.each do |character|
          next if character.nil?
          @map_state[cur_line][cur_col] = character
          @player_pos = Vector[cur_line, cur_col] if character == ?@
          cur_col += 1
        end
        cur_col = 0
        cur_line += 1
      end
    end

    Curses.init_screen
    Curses.curs_set 0
    @win = Curses::Window.new 11, 19, 0, 0
    @win.addstr convert_map_to_string
    @win.refresh
  end

  def process_input
    input = @win.getch
    case input
      when ?q
        @win.close
        exit 0
      when ?w, ?a, ?s, ?d
        move input
      when ?r
        init
    end
  end

  def move(direction)
    future_player_pos = determine_future_pos direction, false
    @player_pos = resolve_move future_player_pos, direction
  end

  def resolve_move(future_player_pos, direction)
    # Resolve state of future cells
    case get_map_char_from_vector future_player_pos
      when ?.
        set_map_char_at_vector ?+, future_player_pos
      when (?\ )
        set_map_char_at_vector ?@, future_player_pos
      when ?o
        future_crate_position = determine_future_pos direction, true
        future_crate_char = get_map_char_from_vector future_crate_position
        case future_crate_char
          when ?.
            set_map_char_at_vector ?*, future_crate_position
          when (?\ )
            set_map_char_at_vector ?o, future_crate_position
          else
            return
        end
        set_map_char_at_vector ?@, future_player_pos
      when ?*
        future_crate_position = determine_future_pos direction, true
        future_crate_char = get_map_char_from_vector future_crate_position
        case future_crate_char
          when ?.
            set_map_char_at_vector ?*, future_crate_position
          when (?\ )
            set_map_char_at_vector ?o, future_crate_position
          else
            return
        end
        set_map_char_at_vector ?+, future_player_pos
      else
        # Do nothing
    end

    # Resolve state of player cell
    case get_map_char_from_vector @player_pos
      when ?@
        set_map_char_at_vector (?\ ), @player_pos
      when ?+
        set_map_char_at_vector (?.), @player_pos
    end

    @player_pos = future_player_pos
  end

  def determine_future_pos(direction, predicting_crate)
    prediction_size = predicting_crate ? 2 : 1
    if direction == ?w
      Vector[@player_pos[0] - prediction_size, @player_pos[1]]
    elsif direction == ?a
      Vector[@player_pos[0], @player_pos[1] - prediction_size]
    elsif direction == ?s
      Vector[@player_pos[0] + prediction_size, @player_pos[1]]
    else
      Vector[@player_pos[0], @player_pos[1] + prediction_size]
    end
  end

  def get_map_char_from_vector(position_vector)
    @map_state[position_vector[0]][position_vector[1]]
  end

  def set_map_char_at_vector (newchar, position_vector)
    @map_state[position_vector[0]][position_vector[1]] = newchar
  end

  def draw_map
    @win.clear
    @win.addstr convert_map_to_string
    @win.refresh
  end

  def convert_map_to_string
    map_string = ''
    @map_state.each do |col|
      col.each do |cell|
        map_string += cell
      end
    end
    map_string
  end

end

sokoban = Sokoban.new
sokoban.play