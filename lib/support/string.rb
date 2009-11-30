class String #:nodoc:
  def interpolate(*args)
    if args.length > 1
      replacements = Hash[*args]
    elsif args.first.kind_of?(Hash)
      replacements = args.first
    else
      raise ArgumentError, "Must pass hash to interpolate."
    end

    string = self.dup
    replacements.each do |key, value|
      if key.kind_of?(Regexp)
        string.gsub!(key, value.to_s)
      else
        string.gsub!(/#{key}/i, value.to_s)
      end
    end

    string
  end
end
