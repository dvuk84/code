#!/usr/bin/python3

# File:        snake.py
# Version:     1.0.0
# Date:        13/4/2019
# Name:        Dan
# E-mail:      dvuk84@gmail.com
# Description: Snake game
# Interpreter: Python 3.6.7
# Libraries:
#   curses
#   random
#   time
#   sys

import time
import random
import curses
from curses import wrapper
from sys import exit

# game difficulty
def difficulty(score, level, r, g, b):
    if score == 3:								# level 3
        r, g, b = 0, 204, 102							# green
        level = 80								# increase speed
    elif score == 6:								# level 6
        r, g, b = 255, 255, 0						        # yellow
        level = 60                                                              # increase speed
    elif score == 9:								# level 9
        r, g, b = 255, 0, 127							# pink
        level = 40								# increase speed
    else:
        level = level								# otherwise, return defaults
        r, g, b = r, g, b

    return level, r, g, b							# return values which we're going to use

# game over
def gameover(stdscr, yh, xw):
    stdscr.addstr(int(yh/2), int(xw/2), "GAME OVER!", curses.A_BLINK)		# display text in the middle of the screen
    stdscr.refresh()
    time.sleep(3)								# wait 3 seconds
    exit()									# and then quit

# main
def main(stdscr):
    yh, xw = stdscr.getmaxyx()							# get height and width of the screen
    curses.newwin(yh, xw, 0, 0)                                                 # create new window with screen size at coordinates
    curses.curs_set(0)                                                          # hide cursor
    key = curses.KEY_RIGHT                                                      # starting snake direction
    snake = [[10, 10], [10, 9], [10, 8]]					# starting snake position
    food = [20, 20]								# starting food position
    score = 0									# starting score
    level = 100									# starting level (100ms refresh rate)
    r, g, b = 51, 153, 255						        # starting background colour
    stdscr.addstr(int(yh/2), int(xw/2), "PRESS ANY KEY TO CONTINUE")		# before we start let the player know
    stdscr.refresh()

    while True:
        level, r, g, b = difficulty(score, level, r, g, b)			# game difficulty
        if curses.can_change_color(): curses.init_color(0, r, g, b)		# background colour
        stdscr.border(1)							# display border (ls, rs, ts, bs, tl, tr, bl, br)
        stdscr.addstr(0, 0, ("SCORE: " + str(score)))				# display score at the top
        stdscr.addstr(0, 15, ("LEVEL: " + str(level)))				# display level

        if score == 10:
            stdscr.addstr(0, int(xw/2), "MAD SKILLS", curses.A_BLINK) 		# display bonus text

        next_key = stdscr.getch()						# get key press
        key = key if next_key == -1 else next_key				# if no key press, keep direction

        stdscr.clear()								# clear the screen

        # draw the entire snake
        for y, x in snake:
            stdscr.addstr(y, x, '*')

        head = snake[0]                                                         # we always need to know where the head is

        # if key press, change direction
        if key == ord('q') or key == 27:					# exit on q or ESC
            break
        elif key == curses.KEY_RIGHT:
            new_head = [head[0], head[1]+1]					# head(10,10) and new_head(10,11)
        elif key == curses.KEY_DOWN:
            new_head = [head[0]+1, head[1]]					# head(10,10) and new_head(11,10)
        elif key == curses.KEY_LEFT:
            new_head = [head[0], head[1]-1]					# head(10,10) and new_head(10,9)
        elif key == curses.KEY_UP:
            new_head = [head[0]-1, head[1]]					# head(10,10) and new_head(9,10)

        # try-except to handle window boundaries
        try:
            stdscr.addstr(new_head[0], new_head[1], '*')			# draw the head
            snake.insert(0, new_head)						# and add new keypress (above) as the position of the new head

            if new_head == food:						# if we hit the food
                curses.beep()
                score += 1							# increase score
                food = [random.randint(1, int(yh)), random.randint(1, int(xw))]	# generate new food position
                stdscr.addch(food[0], food[1], '+')				# draw the new food
            elif snake[0] in snake[1:]:
                gameover(stdscr, yh, xw)					# if we hit ourself we die
            else:
                stdscr.addch(food[0], food[1], '+')				# otherwise draw old food
                snake.pop()							# trim snake's body (since we added a new_head element above)
        except curses.error:
            gameover(stdscr, yh, xw)						# if we hit window borders we die

        stdscr.refresh()							# update the screen with the new content
        stdscr.timeout(level)							# every x ms

# start
wrapper(main)
