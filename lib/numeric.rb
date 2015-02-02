class Numeric
  def human_duration
    secs  = self.to_int
    mins  = secs / 60
    hours = mins / 60
    days  = hours / 24

    "%s:%02d:%02d" % [ hours, mins % 60, secs % 60 ]
  end
end
