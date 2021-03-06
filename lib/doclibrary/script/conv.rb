# -*- encoding: utf-8 -*-
class Doclibrary::Script::Conv

  def self.convert(title_id)
    files_converter(title_id)
    #images_converter(title_id)
  end

  def self.files_converter(title_id)
    @system = 'doclibrary'
    @title = Doclibrary::Control.find(title_id)
    p "files開始:#{Time.now}, #{@title.title}"
    table = db_alias(Doclibrary::File)
    table = table.new
    items = table.find(:all)
    for item in items

      item.content_id = 1
      file = db_alias(Doclibrary::DbFile)
      db_file = file.find_by_id(item.db_file_id)
      unless db_file.blank?
        FileUtils.mkdir_p(item.f_path) unless FileTest.exist?(item.f_path)

        File.open(item.f_name, "wb") { |f|
          f.write db_file.data
        }
      end
      item.save
    end
    p "files終了:#{Time.now}"
  end

  def self.images_converter(title_id)
    @system = 'doclibrary'
    @title = Doclibrary::Control.find(title_id)
    p "Images開始:#{Time.now}, #{@title.title}"
    read_items = db_alias(Doclibrary::Image)
    read_items = read_items.find(:all)
    for read_item in read_items

      item = db_alias(Doclibrary::Doc)
      item = item.new
      item.and :title_id , title_id
      item.and :id , read_item.parent_id
      doc = item.find(:first)
      if doc
        item = db_alias(Doclibrary::File)
        image_file_path = "#{RAILS_ROOT}/public#{read_item.image_file_path}"
        @item = item.new({
          :state => doc.state ,
          :content_type => read_item.content_type ,
          :filename => read_item.filename ,
          :size => read_item.size ,
          :memo => "images_id:#{read_item.id}" ,
          :title_id => read_item.title_id ,
          :parent_id => read_item.parent_id ,
          :content_id => @title.upload_system ,
          :db_file_id => -1
        })
        begin
          f = open(image_file_path, "rb")
          fil = f.read
          f.close
          @item._upload_file(fil)
        rescue
        end

        @item.save
      end
    end

    Doclibrary::Doc.remove_connection
    Doclibrary::File.remove_connection
    Doclibrary::Image.remove_connection
    p "Images終了:#{Time.now}"
  end

  def self.db_alias(item)
    cnn = item.establish_connection
    cnn.spec.config[:database] = @title.dbname.to_s
    Gwboard::CommonDb.establish_connection(cnn.spec.config)
    return item
  end
end
