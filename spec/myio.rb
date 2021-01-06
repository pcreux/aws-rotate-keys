class MyIO
  def initialize
    @content = ""
  end

  def puts(msg)
    @content << msg + "\n"
  end

  def to_s
    @content
  end
end
