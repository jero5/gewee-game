# gewee game
# Copyright (C) 2006  Jeremy Roach
# Licensed under the GNU General Public License version 2

def great_blocking_square(board, empty, point)

  rank = 0

  # help form an invulnerable group
  if (rank < 8 and empty.cnt_player == 1 and empty.cnt_opponent > 0 and
      empty.cnt_opponent + empty.cnt_edge <= 2)
    eligible = false
    if (empty.flags & NORTH_PLAYER != 0)
      if ((empty.flags & WEST_OPPONENT != 0 or
          empty.flags & WEST_EDGE != 0) and
          (empty.flags & EAST_OPPONENT != 0 or
          empty.flags & NORTHEAST_OPPONENT != 0))
        eligible = true
      elsif ((empty.flags & EAST_OPPONENT != 0 or
          empty.flags & EAST_EDGE != 0) and
          (empty.flags & WEST_OPPONENT != 0 or
          empty.flags & NORTHWEST_OPPONENT != 0))
        eligible = true
      end
    elsif (empty.flags & SOUTH_PLAYER != 0)
      if ((empty.flags & WEST_OPPONENT != 0 or
          empty.flags & WEST_EDGE != 0) and
          (empty.flags & EAST_OPPONENT != 0 or
          empty.flags & SOUTHEAST_OPPONENT != 0))
        eligible = true
      elsif ((empty.flags & EAST_OPPONENT != 0 or
          empty.flags & EAST_EDGE != 0) and
          (empty.flags & WEST_OPPONENT != 0 or
          empty.flags & SOUTHWEST_OPPONENT != 0))
        eligible = true
      end
    elsif (empty.flags & WEST_PLAYER != 0)
      if ((empty.flags & NORTH_OPPONENT != 0 or
          empty.flags & NORTH_EDGE != 0) and
          (empty.flags & SOUTH_OPPONENT != 0 or
          empty.flags & SOUTHWEST_OPPONENT != 0))
        eligible = true
      elsif ((empty.flags & SOUTH_OPPONENT != 0 or
          empty.flags & SOUTH_EDGE != 0) and
          (empty.flags & NORTH_OPPONENT != 0 or
          empty.flags & NORTHWEST_OPPONENT != 0))
        eligible = true
      end
    elsif (empty.flags & EAST_PLAYER != 0)
      if ((empty.flags & NORTH_OPPONENT != 0 or
          empty.flags & NORTH_EDGE != 0) and
          (empty.flags & SOUTH_OPPONENT != 0 or
          empty.flags & SOUTHEAST_OPPONENT != 0))
        eligible = true
      elsif ((empty.flags & SOUTH_OPPONENT != 0 or
          empty.flags & SOUTH_EDGE != 0) and
          (empty.flags & NORTH_OPPONENT != 0 or
          empty.flags & NORTHEAST_OPPONENT != 0))
        eligible = true
      end
    end

    if (eligible)
      board_tmp = board.dup
      board_tmp[point] = PIECE_OPPONENT
      remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

      if (!threatened_group(board_tmp, point))
        rank = 8
      end
    end
  end

  # help form an invulnerable group
  if (rank < 8 and empty.cnt_player == 1 and empty.cnt_opponent +
      empty.cnt_corner_player == 0 and empty.cnt_corner_opponent >= 2)
    if (empty.flags & NORTH_PLAYER != 0 and
        empty.flags & NORTHWEST_OPPONENT != 0 and
        empty.flags & NORTHEAST_OPPONENT != 0)
      rank = 8
    elsif (empty.flags & SOUTH_PLAYER != 0 and
        empty.flags & SOUTHWEST_OPPONENT != 0 and
        empty.flags & SOUTHEAST_OPPONENT != 0)
      rank = 8
    elsif (empty.flags & WEST_PLAYER != 0 and
        empty.flags & NORTHWEST_OPPONENT != 0 and
        empty.flags & SOUTHWEST_OPPONENT != 0)
      rank = 8
    elsif (empty.flags & EAST_PLAYER != 0 and
        empty.flags & NORTHEAST_OPPONENT != 0 and
        empty.flags & SOUTHEAST_OPPONENT != 0)
      rank = 8
    end
  end

  # help form an invulnerable group
  if (rank < 8 and empty.cnt_player > 0 and 
      empty.cnt_opponent == 1 and empty.cnt_corner_opponent >= 2)
    eligible = false
    if (empty.flags & NORTHWEST_OPPONENT != 0 and
        empty.flags & SOUTHWEST_OPPONENT != 0 and
        (empty.flags & NORTH_OPPONENT != 0 or
        empty.flags & SOUTH_OPPONENT != 0))
      eligible = true
    elsif (empty.flags & NORTHWEST_OPPONENT != 0 and
        empty.flags & NORTHEAST_OPPONENT != 0 and
        (empty.flags & WEST_OPPONENT != 0 or
        empty.flags & EAST_OPPONENT != 0))
      eligible = true
    elsif (empty.flags & NORTHEAST_OPPONENT != 0 and
        empty.flags & SOUTHEAST_OPPONENT != 0 and
        (empty.flags & NORTH_OPPONENT != 0 or
        empty.flags & SOUTH_OPPONENT != 0))
      eligible = true
    elsif (empty.flags & SOUTHWEST_OPPONENT != 0 and
        empty.flags & SOUTHEAST_OPPONENT != 0 and
        (empty.flags & WEST_OPPONENT != 0 or
        empty.flags & EAST_OPPONENT != 0))
      eligible = true
    end

    if (eligible)
      board_tmp = board.dup
      board_tmp[point] = PIECE_OPPONENT
      remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

      if (!threatened_group(board_tmp, point))
        rank = 8
      end
    end
  end

  # block player from connecting
  if (rank < 8 and empty.cnt_player == 2 and empty.cnt_opponent > 0)
    eligible = false
    if (empty.flags & NORTH_PLAYER != 0 and
        empty.flags & SOUTH_PLAYER != 0)
      eligible = true
    elsif (empty.flags & WEST_PLAYER != 0 and
        empty.flags & EAST_PLAYER != 0)
      eligible = true
    end

    if (eligible)
      board_tmp = board.dup
      board_tmp[point] = PIECE_OPPONENT
      remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

      if (!threatened_group(board_tmp, point))
        rank = 8
      end
    end
  end

  # wedge player groups
  if (rank < 8 and empty.cnt_player >= 2 and empty.cnt_opponent == 1 and
      distinct_groups(board, PIECE_PLAYER, point))
    board_tmp = board.dup
    board_tmp[point] = PIECE_OPPONENT
    remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

    num_empties = count_group_empties(board_tmp, point)

    adjacent_squares(board_tmp, PIECE_PLAYER, point) do |plyr|

      if (!excessive_group_empties(board_tmp.dup, [], [], num_empties - 1, plyr))
        rank = 8
        true
      else
        false
      end
    end
  end

  rank   # true if rank != 0
end

def opponent_move(board, player_point)
  begin
    best_empties = []
    best_rank = -1  # the rank of all the squares in best_empties
    collected_threatened_opponent_groups = false

    for point in 0...SQUARES

      if (board[point].piece == PIECE_EMPTY)

        empty = describe_square(board, point)
        rank = 0

        # if i can remove a player group, do so if player could possibly escape, or
        # any groups of mine that are threatened become nonthreatened
        if (rank < RANK_HIGHEST and empty.cnt_player > 0)
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          altered = remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (altered)
            board_tmp2 = board.dup
            board_tmp2[point] = PIECE_PLAYER
            remove_surrounded_pieces(board_tmp2, PIECE_OPPONENT, point)

            if (!threatened_group(board_tmp2, point))
              rank = RANK_HIGHEST
              rank += 0.001 * count_largest_removed_group(board, board_tmp, PIECE_PLAYER, point)
            else
              if (!collected_threatened_opponent_groups)
                threatened_opponent_groups =
                  threatened_groups_squares(board, PIECE_OPPONENT)
                collected_threatened_opponent_groups = true
              end

              for oppo in threatened_opponent_groups

                if (!threatened_group(board_tmp, oppo))
                  rank = RANK_HIGHEST
                  rank += 0.001 * count_largest_removed_group(board, board_tmp, PIECE_PLAYER, point)
                  break
                end
              end
            end
          end
        end

        # try to not let player remove my pieces
        if (rank < 70 and empty.cnt_opponent > 0)
          board_tmp = board.dup
          board_tmp[point] = PIECE_PLAYER
          altered = remove_surrounded_pieces(board_tmp, PIECE_OPPONENT, point)

          if (altered)
            board_tmp = board.dup
            board_tmp[point] = PIECE_OPPONENT
            remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

            if (!threatened_group(board_tmp, point))
              rank = 70
            end
          end
        end

        # cause two separate player groups to be threatened simultaneously
        if (rank < 65 and empty.cnt_opponent + empty.cnt_edge == 0 and
            empty.cnt_player == 2 and empty.cnt_corner_opponent > 0)
          eligible = false
          if (empty.flags & NORTH_PLAYER != 0 and
              empty.flags & WEST_PLAYER != 0 and
              empty.flags & NORTHWEST_OPPONENT != 0)
            eligible = true
          elsif (empty.flags & NORTH_PLAYER != 0 and
              empty.flags & EAST_PLAYER != 0 and
              empty.flags & NORTHEAST_OPPONENT != 0)
            eligible = true
          elsif (empty.flags & SOUTH_PLAYER != 0 and
              empty.flags & WEST_PLAYER != 0 and
              empty.flags & SOUTHWEST_OPPONENT != 0)
            eligible = true
          elsif (empty.flags & SOUTH_PLAYER != 0 and
              empty.flags & EAST_PLAYER != 0 and
              empty.flags & SOUTHEAST_OPPONENT != 0)
            eligible = true
          end

          if (eligible)
            board_tmp = board.dup
            board_tmp[point] = PIECE_OPPONENT
            remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

            cnt = 0
            adjacent_squares(board_tmp, PIECE_PLAYER, point) do |plyr|
              if (threatened_group(board_tmp, plyr))
                cnt += 1
              end
              false
            end

            if (cnt == empty.cnt_player)
              rank = 65
            end
          end
        end

        # move here if it seems certain that a player group would be doomed
        if (rank < 60 and empty.cnt_player > 0)
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (!threatened_group(board_tmp, point) or !excessive_group(board_tmp.dup, [], 3, point))

            adjacent_squares(board_tmp, PIECE_PLAYER, point) do |plyr|

              if (excessive_group(board_tmp.dup, [], 3, plyr) and
                  doomed_group(board_tmp, 'player', plyr))
                rank = 60
                true
              else
                false
              end
            end
          end
        end

        # put pressure on player group close to the board edge
        if (rank < 55 and empty.cnt_player > 0)
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (!threatened_group(board_tmp, point))

            adjacent_squares(board_tmp, PIECE_PLAYER, point) do |plyr|

              if (threatened_group(board_tmp, plyr))
                empties = group_empty_squares(board_tmp, plyr)
                emti = empties[0]
                if (almost_near_edge(emti) or near_edge(emti) or
                    almost_near_edge(plyr) or near_edge(plyr) or
                    almost_near_edge(point))
                  rank = 55.1
                  if (great_blocking_square(board, empty, point) != 0)
                    rank += 0.2
                  end
                  if (doomed_group(board_tmp, 'player', plyr))
                    rank += 0.1
                  end
                  board_tmp2 = board_tmp.dup
                  board_tmp2[emti] = PIECE_PLAYER
                  remove_surrounded_pieces(board_tmp2, PIECE_OPPONENT, emti)

                  rank -= 0.001 * count_group_empties(board_tmp2, emti)
                  true
                else
                  false
                end
              else
                false
              end
            end
          end
        end

        # cause a player group to be threatened,
        # and a different one to be almost threatened
        if (rank < 50 and (empty.cnt_player == 2 or
            (empty.cnt_player == 3 and empty.cnt_opponent == 1)))
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (!threatened_group(board_tmp, point))

            conditions = {}
            adjacent_squares(board_tmp, PIECE_PLAYER, point) do |plyr|

              if (threatened_group(board_tmp, plyr))
                conditions['tg'] = true
              elsif (!excessive_group_empties(board_tmp.dup, [], [], 2, plyr))
                conditions['ege'] = true
              end

              if (conditions.length == 2)
                rank = 50
                true
              else
                false
              end
            end
          end
        end

        # defend almost threatened group
        if (rank < 45 and empty.cnt_player == 0 and empty.cnt_opponent <= 1 and
            empty.cnt_edge <= 1 and empty.cnt_corner_opponent > 0)

          corner_squares(board, PIECE_OPPONENT, point) do |oppo|
            eligible = false
            nonempty = describe_square(board, oppo)

            if (empty.cnt_opponent == 0 and empty.cnt_edge == 1)
              if (empty.flags & NORTH_EDGE != 0)
                if (oppo == southwest_square(point) and
                    nonempty.flags & SOUTHEAST_OPPONENT != 0)
                  eligible = true
                elsif (oppo == southeast_square(point) and
                    nonempty.flags & SOUTHWEST_OPPONENT != 0)
                  eligible = true
                end
              elsif (empty.flags & SOUTH_EDGE != 0)
                if (oppo == northwest_square(point) and
                    nonempty.flags & NORTHEAST_OPPONENT != 0)
                  eligible = true
                elsif (oppo == northeast_square(point) and
                    nonempty.flags & NORTHWEST_OPPONENT != 0)
                  eligible = true
                end
              elsif (empty.flags & WEST_EDGE != 0)
                if (oppo == northeast_square(point) and
                    nonempty.flags & SOUTHEAST_OPPONENT != 0)
                  eligible = true
                elsif (oppo == southeast_square(point) and
                    nonempty.flags & NORTHEAST_OPPONENT != 0)
                  eligible = true
                end
              elsif (empty.flags & EAST_EDGE != 0)
                if (oppo == northwest_square(point) and
                    nonempty.flags & SOUTHWEST_OPPONENT != 0)
                  eligible = true
                elsif (oppo == southwest_square(point) and
                    nonempty.flags & NORTHWEST_OPPONENT != 0)
                  eligible = true
                end
              end
            elsif (near_edge(oppo))
              eligible = true
            elsif (empty.cnt_opponent == 0 and excessive_group(board.dup, [], 1, oppo))
              eligible = true
            elsif (empty.cnt_opponent == 0)
              # don't allow player a move that could cause two separate
              # oppo groups to be threatened simultaneously
              corner_squares(board, PIECE_OPPONENT, oppo) do |popo|
                if (count_group_empties(board, popo) == 2)
                  eligible = true
                else
                  false
                end
              end
            end

            if (eligible and count_group_empties(board, oppo) == 2)
              rank = 45
              true
            else
              false
            end
          end
        end

        # defend almost threatened group
        if (rank < 45 and empty.cnt_player + empty.cnt_corner_player > 0 and
            ((empty.cnt_opponent >= 1 and empty.cnt_opponent <= 2) or
            (empty.cnt_opponent == 3 and empty.cnt_player > 0)))
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (excessive_group(board_tmp.dup, [], 2, point) and
              excessive_group_empties(board_tmp.dup, [], [], 2, point))

            adjacent_squares(board, PIECE_OPPONENT, point) do |oppo|
              if (count_group_empties(board, oppo) == 2)
                rank = 45
                true
              else
                false
              end
            end
          end
        end

        # defend or 'smartly' sacrifice almost threatened group
        if (rank < 40 and empty.cnt_opponent == 1 and almost_near_edge(point))
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (!threatened_group(board_tmp, point))

            adjacent_squares(board, PIECE_OPPONENT, point) do |oppo|
              if (near_edge(oppo) and !excessive_group(board.dup, [], 1, oppo) and
                  count_group_empties(board, oppo) == 2)
                rank = 40
                true
              else
                false
              end
            end
          end
        end

        rank_tmp = great_blocking_square(board, empty, point)
        if (rank < rank_tmp)
          rank = rank_tmp
        end

        if (rank < 8 and empty.cnt_opponent == 1 and
            empty.cnt_edge == 1 and empty.cnt_corner_player == 2)
          eligible = false
          if (empty.flags & WEST_EDGE != 0 and
              empty.flags & EAST_OPPONENT != 0)
            eligible = true
          elsif (empty.flags & EAST_EDGE != 0 and
              empty.flags & WEST_OPPONENT != 0)
            eligible = true
          elsif (empty.flags & NORTH_EDGE != 0 and
              empty.flags & SOUTH_OPPONENT != 0)
            eligible = true
          elsif (empty.flags & SOUTH_EDGE != 0 and
              empty.flags & NORTH_OPPONENT != 0)
            eligible = true
          end

          if (eligible)
            board_tmp = board.dup
            board_tmp[point] = PIECE_OPPONENT
            remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

            if (!threatened_group(board_tmp, point))
              rank = 8
            end
          end
        end

        # connect opponent groups
        if (rank < 6 and ((empty.cnt_opponent == 2 and
            empty.cnt_player + empty.cnt_corner_player > 0) or
            (empty.cnt_opponent == 3 and empty.cnt_player > 0)) and
            distinct_groups(board, PIECE_OPPONENT, point))
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          num_empties = count_group_empties(board_tmp, point)
          lowest_num_empties = SQUARES

          adjacent_squares(board, PIECE_OPPONENT, point) do |oppo|

            if (excessive_group(board.dup, [], 3, oppo))
              cnt = count_group_empties(board, oppo)
              if (cnt < lowest_num_empties)
                lowest_num_empties = cnt
              end
            end
            false
          end

          if (num_empties > lowest_num_empties)
            rank = 6
          end
        end

        if (rank < 5)
          if (empty.cnt_player == 1 and empty.cnt_opponent == 0 and
              empty.cnt_edge <= 1 and empty.cnt_corner_opponent > 0)
            rank = 5
          elsif (empty.cnt_player == 1 and
              empty.cnt_opponent == 1 and empty.cnt_edge == 0)
            rank = 5
          elsif (empty.cnt_player + empty.cnt_edge == 0 and
              empty.cnt_opponent == 1 and empty.cnt_corner_player > 0)
            rank = 5
          elsif (empty.cnt_player == 2 and
              empty.cnt_opponent + empty.cnt_edge == 0 and
              !almost_near_edge(point) and
              distinct_groups(board, PIECE_PLAYER, point))
            rank = 5
          elsif (empty.cnt_opponent == 0 and
              empty.cnt_player + empty.cnt_edge == 1 and
              ((almost_near_edge(point) and empty.cnt_corner_player >= 3) or
              (near_edge(point) and empty.cnt_corner_player == 2)))
            rank = 5
          elsif (empty.cnt_player + empty.cnt_opponent + empty.cnt_edge +
              empty.cnt_corner_player + empty.cnt_corner_opponent == 0)
            rank = 5
          end
        end

        if (rank < 4 and empty.cnt_player + empty.cnt_opponent + empty.cnt_edge == 0)
          rank = 4
        end

        if (rank < 2 and empty.cnt_player + empty.cnt_opponent + empty.cnt_edge == 1)
          rank = 2.9
        end

        if (rank < 2 and empty.cnt_player + empty.cnt_opponent + empty.cnt_edge == 2)
          eligible = true
          if (empty.cnt_player > 0)
            adjacent_squares(board, PIECE_EMPTY, point) do |emti|
              empty2 = describe_square(board, emti)
              if (empty2.cnt_opponent > 0)
                eligible = false
                true
              else
                false
              end
            end
          end
          if (eligible)
            rank = 2.8
          end
        end

        if (rank < 2 and empty.cnt_player + empty.cnt_opponent + empty.cnt_edge == 3)
          rank = 2
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          rank += 0.001 * count_group_empties(board_tmp, point)

          if (empty.cnt_opponent > 0 and empty.cnt_player > 0)
            rank += 0.5
          elsif (empty.cnt_opponent > 0 and empty.cnt_corner_player > 0)
            rank += 0.3
          elsif (empty.cnt_opponent > 0)
            rank += 0.2
          end
        end

        if (rank < 2 and empty.cnt_player + empty.cnt_opponent + empty.cnt_edge == 4 and
            empty.cnt_player > 0 and empty.cnt_opponent > 0)
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          num = count_besieged_group_empties(board_tmp, point)

          if (num.nonbesieged >= 2)
            rank = 2.4
            adjacent_squares(board, PIECE_OPPONENT, point) do |oppo|
              num = count_besieged_group_empties(board, oppo)
              if (num.nonbesieged == 0)
                rank += 0.003
              elsif (num.nonbesieged == 1)
                rank += 0.002
              end
              false
            end
          elsif (!threatened_group(board_tmp, point) or
              !excessive_group(board_tmp.dup, [], 3, point))
            rank = 2.4
          end
        end

        # one square of this rank is sufficient
        if (best_rank < 1 and rank < 1)
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (!threatened_group(board_tmp, point))
            rank = 1
          end
        end

        # only one 'handler' can rank an empty square where
        # if an opponent piece were placed on it, player
        # pieces would be removed. so undo any unauthorized ranking
        if (rank < RANK_HIGHEST and empty.cnt_player > 0)
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          altered = remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (altered)
            rank = 1.5
            rank += 0.001 * count_largest_removed_group(board, board_tmp, PIECE_PLAYER, point)
          end
        end

        if (rank < 19 and rank >= 4 and valid_point(player_point))
          rank += near_square_bonus(point, player_point)
        end

        if (rank >= best_rank)

          # check for invalid suicide move
          board_tmp = board.dup
          board_tmp[point] = PIECE_OPPONENT
          remove_surrounded_pieces(board_tmp, PIECE_PLAYER, point)

          if (surrounded_group(board_tmp, point))
            next
          end

          if (rank > best_rank)
            best_empties = [point]
            best_rank = rank
          else
            best_empties << point
          end
        end
      end
    end

#    puts "#{best_rank}"

    if (best_rank == -1)
      return -1
    end

    choice = rand(best_empties.length)
    point = best_empties[choice]

    board[point] = PIECE_OPPONENT
    point

  rescue Exception => errmsg
    puts "error: opponent_move: #{errmsg}"
    -1
  end
end
