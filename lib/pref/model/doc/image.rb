module Pref::Model::Doc::Image
  def self.included(mod)
    mod.has_many :images, :primary_key => 'id', :foreign_key => 'doc_id', :class_name => 'Pref::DocImage',
      :dependent => :destroy
      
    mod.after_validation :validate_doc_images
    mod.after_save  :save_doc_images
    mod.after_save  :publish_doc_images
    mod.after_save  :close_doc_images
  end
  
  attr_accessor :_new_images, :_destroy_images
  
  def find_doc_image_by_name(name)
    return nil if images.size == 0
    images.each do |img|
      return img if img.name == name.to_s
    end
    return nil
  end
  
  def validate_doc_images
    valid = true
    
    max_size     = 1024**2 * 2;
    max_size_str = '2MB';
    
    _validate = Proc.new do |_file|
      if _file[:upload] != ''
        if _file[:upload].size > max_size
          errors.add_to_base "ファイルサイズが #{max_size_str} を超えています (#{_file[:upload].original_filename})"
          valid = false
        end
      end
    end
    
    _new_images.each do |k, file|
      _validate.call(file)
    end if _new_images
    
    return valid
  end
  
  def save_doc_images
    return true  unless _new_images
    return false unless id
    return false if @save_doc_images_callback_flag
    
    @save_doc_images_callback_flag = true
    
    if _destroy_images
      _destroy_images.keys.each do |_image_id|
        images.each do |_image|
          _image.destroy if _image.id.to_s == _image_id.to_s
        end
      end
      images(true)
    end
    
    _new_images.each do |k, _image|
      name = _image[:name]
      file = _image[:upload]
      
      next if file.size.to_i <= 0
      
      name = File.basename(file.original_filename) if name.to_s == ''
      
      if image = find_doc_image_by_name(name)
        image.remove_file
      else
        image = Pref::DocImage.new
        image.content_id = content_id
        image.doc_id     = id
        image.name       = name
      end
      return false unless image.save_with_file(file)
    end
    
    images(true)
    return true
  end
  
  def publish_doc_images
    return true unless @save_mode == :publish
    
    images.each do |image|
      image.publish
    end
    return true
  end
  
  def close_doc_images
    return true unless @save_mode == :close
    
    images.each do |image|
      image.close
    end
    return true
  end
end
