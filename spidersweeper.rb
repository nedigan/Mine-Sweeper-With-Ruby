require 'gosu'

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

WIN_WIDTH = 800
WIN_HEIGHT = 800
GAME_HEIGHT = 400
GAME_WIDTH = 400
CELL_DIM = 20

class Cell
  attr_accessor :amount_of_spiders, :spider, :x, :y, :clicked, :flagged

  def initialize()
    @amount_of_spiders = 0
    @spider = false
    @flagged = false
    @clicked = false
  end
end

class Button
  attr_accessor :x, :y, :height, :width, :text, :highlighted

  def initialize(x,y,width,height, text)
    @x = x
    @y = y
    @height = height
    @width = width
    @text = text
  end
end

class GameWindow < Gosu::Window
  def initialize
    super WIN_WIDTH, WIN_HEIGHT, false
    self.caption = "Spider Sweeper!"

    x_cell_count = GAME_WIDTH/CELL_DIM
    y_cell_count =  GAME_HEIGHT/CELL_DIM

    #Whether player has lost
    @game_over = false
    #whether player has won
    @game_won = false
    #difficulty 0 = Easy, 1 = Medium, 2 = Hard
    @difficulty = 0

    #position of grid
    @cells_x = 200
    @cells_y = 200

    #Amount of spiders
    @total_spiders = 30
    #flag left to use
    @flags = @total_spiders
    #flags the user actually got right
    @correct_flags = @total_spiders

    #used to reset timer
    @start_time = Gosu::milliseconds
    @timer = 0

    #play song
    @song = Gosu::Song.new("Media/theme.wav")
  	@song.play(true)

    #initialize fonts and images
    @spide_img = Gosu::Image.new("Media/spider.png")
    @cell_font = Gosu::Font.new(20)
    @title = Gosu::Image.new("Media/title.png")
    @mid_font = Gosu::Font.new(25)
    @large_font = Gosu::Font.new(72)
    @highscores = read_file("highscores.txt")

    #create grid
    @grid = Array.new(x_cell_count)
    for i in 0..@grid.length-1
        @grid[i] = Array.new(y_cell_count)
    end
    
    #fill grid with spiders
    fill_grid(@grid)

    #initialize buttons
    @buttons = create_buttons()
  end

  #show mouse
  def needs_cursor?
    true
  end

  def read_file(file_name)
    file = File.new(file_name, "r")
    scores = []
    scores << file.gets().chomp
    scores << file.gets().chomp
    scores << file.gets().chomp
    file.close()
    return scores
  end

  def create_buttons()
    buttons = []

    width = 150
    height = 30
    #Difficulty Buttons
    buttons << Button.new(10, @cells_y + 30, width, height, "Easy") #Easy
    buttons << Button.new(10, @cells_y + 70, width, height, "Medium") #Medium
    buttons << Button.new(10, @cells_y + 110, width, height, "Hard") #Hard

    #Reset Buttons
    buttons << Button.new(10, @cells_y + 230, width, height, "Reset") #Reset Game
    buttons << Button.new(10, @cells_y + 270, width, height, "Exit") #Exit Game
  end

  def open_surrounding_cells(x,y, grid)
    if grid[x][y].flagged
      return
    end
    
    grid[x][y].clicked = true
    
    if grid[x][y].amount_of_spiders > 0
      return
    end

    for xoff in -1..1
      for yoff in -1..1
        i = x + xoff
        j = y + yoff
        if (i > -1 and i < grid.length && j < grid[0].length and j > - 1)
          if (grid[i][j].clicked)
            next
          end
          open_surrounding_cells(i,j,grid)
        end
      end
    end
  end

  def update_surrounding_cells(x,y,grid)
    for xoff in -1..1
      for yoff in -1..1
        i = x + xoff
        j = y + yoff
        if (i > -1 and i < grid.length && j < grid[0].length and j > - 1)
          grid[i][j].amount_of_spiders += 1
        end
      end
    end
  end

  #Checks neighbouring cells
  def count_neigbours(grid)
    #loop all cells
    for x in 0..grid.length-1
      for y in 0..grid[0].length-1
        if grid[x][y].spider
          update_surrounding_cells(x,y,grid)
        end
      end
    end
  end

  #resets game variables
  def reset_game()
    @game_over = false
    @flags = @total_spiders
    @correct_flags = @total_spiders
    @game_won = false
    @start_time = Gosu::milliseconds
    fill_grid(@grid)
  end

  # Returns an array of the cell x and y coordinates that were clicked on
  def mouse_over_cell(mouse_x, mouse_y)
    if (mouse_x < @cells_x.to_f || mouse_x >= @cells_x.to_f + GAME_WIDTH) || (mouse_y < @cells_y.to_f || mouse_y >= @cells_y.to_f + GAME_HEIGHT)
      return Array.new()
    end
    x = ((mouse_x - @cells_x) / CELL_DIM).floor()
    y = ((mouse_y - @cells_y) / CELL_DIM).floor()
    coordinates = []
    coordinates << x
    coordinates << y
    return coordinates
  end

  #flags or unflags the cell
  def flag_cell(cell)
    if (cell.clicked)
      return
    end

    if (cell.flagged)
      @flags += 1
      cell.flagged = false
      if (cell.spider)
        @correct_flags += 1
      end
    elsif (@flags > 0)
      @flags -= 1
      cell.flagged = true
      if (cell.spider)
        @correct_flags -= 1
      end
    end

    if (@correct_flags < 1)
      @game_won = true

      #if player beats highscore re write score
      if (@timer / 1000 < @highscores[@difficulty].to_i)
        @highscores[@difficulty] = @timer / 1000
      end
    end
  end

  #clicks the cell and updates accordingly
  def click_cell(x,y,grid)
    if grid[x][y].flagged
      return
    end

    grid[x][y].clicked = true
    
    if (grid[x][y].amount_of_spiders == 0)
      open_surrounding_cells(x,y,@grid)
    end

    if (grid[x][y].spider)
      @game_over = true
    end
  end

  #checks if mouse if over a button
  def mouse_over_button(mouse_x, mouse_y)
    for i in 0..@buttons.length-1
      if (mouse_x > @buttons[i].x && mouse_x < @buttons[i].x + @buttons[i].width) && (mouse_y > @buttons[i].y && mouse_y < @buttons[i].y + @buttons[i].height)
        @buttons[i].highlighted = true
        return i
      else
        @buttons[i].highlighted = false
      end
    end
  end

  #writes new scores to file
  def write_scores_to_file(scores)
    file = File.new("highscores.txt", "w")
    file.puts(scores[0])
    file.puts(scores[1])
    file.puts(scores[2])
    file.close()
  end

  #checks for button input
  def button_down(id)
    coordinates = mouse_over_cell(mouse_x, mouse_y)

    case id
    when Gosu::MsLeft  
      if coordinates.length != 0
        x = coordinates[0]
        y = coordinates[1]

        click_cell(x,y,@grid)
      else
        button_index = mouse_over_button(mouse_x(),mouse_y())

        case button_index
        when 0 #clicked easy button
          @total_spiders = 30
          @difficulty = 0
          reset_game()
        when 1 #clicked medium button
          @total_spiders = 50
          @difficulty = 1
          reset_game
        when 2 #clicked hard button
          @total_spiders = 75
          @difficulty = 2
          reset_game
        when 3 
          reset_game()
        when 4
          write_scores_to_file(@highscores)
          close()
        end
      end
    when Gosu::MsRight
      if coordinates.length != 0
        x = coordinates[0]
        y = coordinates[1]

        flag_cell(@grid[x][y])
      end
    end
  end

  def update
    mouse_over_button(mouse_x,mouse_y)
  end

  #fill cells with spiders(mines)
  def fill_grid(grid)
  number_of_spiders = @total_spiders
  #reset cells
  for x in 0..@grid.length-1
    for y in 0..@grid[x].length-1
        @grid[x][y] = Cell.new()
    end
  end
    
  #fill cells
    while number_of_spiders > 0
      x = rand(@grid.length)
      y = rand(@grid[0].length)

      if (@grid[x][y].spider != true)
        @grid[x][y].spider = true
        number_of_spiders -= 1
      end
    end

    count_neigbours(@grid)
  end

  #draws cells and there colours/text
  def draw_cells(grid)
    for x in 0..grid.length-1
      for y in 0..grid[x].length-1
        color = Gosu::Color::GRAY
        if (grid[x][y].flagged) 
          color = Gosu::Color::GREEN
        end
        if (grid[x][y].clicked)
          color = Gosu::Color::WHITE
        end
        if (grid[x][y].spider and @game_over)
          @spide_img.draw((x * CELL_DIM) + @cells_x,(y * CELL_DIM) + @cells_y, z = ZOrder::TOP, 0.015, 0.015)
          color = Gosu::Color::RED
        elsif (grid[x][y].amount_of_spiders > 0 and grid[x][y].clicked) 
          #Cell font
          @cell_font.draw_text(grid[x][y].amount_of_spiders.to_s, (x * CELL_DIM) + @cells_x, (y * CELL_DIM) + @cells_y, z = ZOrder::TOP, 1.0, 1.0, Gosu::Color::BLACK)
        end
        Gosu.draw_rect((x * CELL_DIM) + @cells_x,(y * CELL_DIM) + @cells_y,CELL_DIM - 2, CELL_DIM - 2, color, ZOrder::MIDDLE, mode=:default)
      end
    end
  end
  
  #draws all ui elements
  def draw_ui()
    #title
    @title.draw(100, 0,z = ZOrder::TOP, 0.3, 0.3)

    #scoring
    @mid_font.draw_text("Spiders left: #{@flags.to_s}", @cells_x, @cells_y + GAME_HEIGHT + 20, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::BLACK)

    #difficulty
    @mid_font.draw_text("Difficulty:", 10, @cells_y, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::BLACK)

    #High score
    @mid_font.draw_text("Quickest Time:", @cells_x + GAME_WIDTH + 10, @cells_y, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::BLACK)
    @mid_font.draw_text("#{@highscores[@difficulty]} seconds", @cells_x + GAME_WIDTH + 10, @cells_y + 30, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::BLACK)

    #reset
    @mid_font.draw_text("Options:", 10, @cells_y + 200, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::BLACK)

    #timer
    if (!@game_won && !@game_over)
      @timer = Gosu::milliseconds - @start_time
    end
    @mid_font.draw_text("Time: #{(@timer) / 1000}", @cells_x + GAME_WIDTH - 100, @cells_y + GAME_HEIGHT + 20, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::BLACK)

    #win screen
    if (@game_won)
      @large_font.draw_text("Winner!", @cells_x + 100, @cells_y + GAME_HEIGHT / 2, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::BLACK)
    end

    #draw buttons
    for i in 0..@buttons.length-1
      if (@buttons[i].highlighted)
        Gosu.draw_rect(@buttons[i].x - 2, @buttons[i].y - 2, @buttons[i].width + 4, @buttons[i].height + 4, Gosu::Color::BLACK, ZOrder::BACKGROUND, mode=:default)
      end
      Gosu.draw_rect(@buttons[i].x, @buttons[i].y, @buttons[i].width, @buttons[i].height, Gosu::Color::GRAY, ZOrder::MIDDLE, mode=:default)
      @mid_font.draw_text(@buttons[i].text, @buttons[i].x, @buttons[i].y, z = ZOrder::TOP, 1.0,1.0, Gosu::Color::WHITE)
    end
  end

  def draw
    #Draw background
    Gosu.draw_rect(0, 0, WIN_WIDTH, WIN_HEIGHT, 0xff_999897, ZOrder::BACKGROUND, mode=:default)
    #Draw cells
    draw_cells(@grid)
    #draw ui
    draw_ui()
  end
end

window = GameWindow.new
window.show