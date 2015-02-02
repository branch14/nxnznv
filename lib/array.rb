class Array
  # works on 2dimensional arrays
  def to_csv
    map { |e| e.to_a * ',' } * "\n"
  end
end
