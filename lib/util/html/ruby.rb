class Util::Html::Ruby
  @chasenrc = Rails.root + '/ext/ruby/chasenrc'

  def self.chasen_is?
    begin
      require 'chasen'
    rescue LoadError
      return nil
    rescue
      return nil
    end
    return true
  end

  def self.convert(str)
    @@tag    = nil
    @@script = nil

    return str unless chasen_is?

    if str =~ /\n/
      buf = ''
      str.split(/\n/).each_with_index do |line, k|
        buf += "\n" if k != 0
        buf += convert_line(line)
      end
      return buf
    else
      return convert_line(str)
    end
  end

  def self.convert_line(str)
    return str if str == ''

    Chasen.getopt('-i', 'w')
    Chasen.getopt('-r', @chasenrc)
    Chasen.getopt('-F', '%ps %pe %m %y %h %H\n')

    begin
      res = {}
      str = str.gsub(/ +/, ' ')
      Chasen.sparse(str).split(/\n/).each do |line|
        break if line == 'EOS'
        data = line.split(/ /)
        res["#{data[0]}".to_i] = data
      end
    rescue
      return str
    end

    i   = 0
    lim = 0
    buf = ''

    while i < str.length
      lim += 1
      break if lim > 1000

      unless res.key?(i)
        buf += str.slice(i, 1)
        i += 1
        next
      end

      if res[i][2] == '<'
        @@tag = ''
      elsif res[i][2] == '>'
        if @@tag =~ /^script/
          @@script = true
        elsif @@tag =~ /^\/script/
          @@script = nil
        end
        @@tag = nil
      elsif @@tag
        @@tag << res[i][2]
      end

      ruby = false
      if @@tag
        ruby = false
      elsif @@script
        ruby = false
      elsif res[i][4] == '81'
        ruby = false
      elsif res[i][2] =~ /[一-龠]+/
        ruby = true
      end

      if ruby == true
        buf += "<ruby><rb>#{res[i][2]}</rb><rp>(</rp><rt>#{res[i][3].tr('ァ-ン', 'ぁ-ん')}</rt><rp>)</rp></ruby>"
      else
        buf += res[i][2]
      end
      i = res[i][1].to_i
    end

    buf
  end
end
