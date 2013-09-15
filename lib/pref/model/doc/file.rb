module Pref::Model::Doc::File
  def self.included(mod)
    mod.has_many :file_groups, :foreign_key => 'doc_id', :class_name => 'Pref::DocFileGroup',
      :primary_key => 'id', :order => :name, :dependent => :destroy
      
    mod.has_many :files,       :foreign_key => 'doc_id', :class_name => 'Pref::DocFile',
      :primary_key => 'id'
      
    mod.after_validation :validate_doc_files
    mod.after_save  :save_doc_files
    mod.after_save  :publish_doc_files
    mod.after_save  :close_doc_files
  end
  
  attr_accessor :_new_file_groups, :_file_groups, :_destroy_file_groups
  attr_accessor :_new_files, :_files, :_destroy_files
  
  def get_file_group(id)
    file_groups.each do |group|
      return group if group.id.to_s == id.to_s
    end
    return nil
  end
  
  def get_file_by_name(name)
    files.each do |file|
      return file if file.name == name
    end
    return nil
  end
  
  def validate_doc_files
    valid = true
    
    max_size     = 1024**2 * 20
    max_size_str = '20MB'
    
    _validate = Proc.new do |_file|
      if _file[:upload] != ''
        if _file[:upload].size > max_size
          errors.add_to_base "ファイルサイズが #{max_size_str} を超えています (#{_file[:upload].original_filename})"
          valid = false
        end
      end
    end
    
    _new_files.each do |k1, groups|
      groups.each do |k2, file|
        _validate.call(file)
      end
    end if _new_files
    
    _files.each do |k1, groups|
      groups.each do |k2, file|
        _validate.call(file)
      end
    end if _files
    
    return valid
  end
  
  def save_doc_files
    return false unless id
    return false if @save_doc_files_callback_flag
    
    @save_doc_files_callback_flag = true
    
    if _destroy_files
      _destroy_files.each do |_group_id, _files|
        _files.keys.each do |_file_id|
          files.each do |_file|
            _file.destroy if _file.id.to_s == _file_id.to_s
          end
        end
      end
      files(true)
    end
    
    if _destroy_file_groups
      _destroy_file_groups.keys.each do |_group_id|
        file_groups.each do |_group|
          _group.destroy if _group.id.to_s == _group_id.to_s
        end
      end
      file_groups(true)
    end
    
    _upload = Proc.new do |_up_group, _up_file|
      up_name = _up_file[:name]
      up_file = _up_file[:upload]
      
      next if up_file.size.to_i <= 0
      
      up_name = File.basename(up_file.original_filename) if name.to_s == ''
      
      if _doc_file = get_file_by_name(name)
        _doc_file.remove_file
      else
        _doc_file = Pref::DocFile.new
        _doc_file.content_id = content_id
        _doc_file.doc_id     = id
        _doc_file.group_id   = _up_group.id
        _doc_file.name       = up_name
      end
      _doc_file.save_with_file(up_file)
    end
    
    if _files
      _files.each do |_group_id, new_files|
        next unless _group = get_file_group(_group_id)
        new_files.each do |k, new_file|
          _upload.call(_group, new_file)
        end
      end
      files(true)
    end
    
    if _new_file_groups
      _new_file_groups.each do |k, _name|
        
        next if _name.to_s == ''
        
        new_group = Pref::DocFileGroup.new
        new_group.content_id = content_id
        new_group.doc_id     = id
        new_group.name       = _name
        next unless new_group.save()
        
        next if !_new_files || !_new_files[k]
        
        _new_files[k].each do |k2, new_file|
          _upload.call(new_group, new_file)
        end
      end
      files(true)
    end
    
    return true
  end
  
  def publish_doc_files
    return true unless @save_mode == :publish
    
    files.each do |file|
      file.publish
    end
    return true
  end
  
  def close_doc_files
    return true unless @save_mode == :close
    
    files.each do |file|
      file.close
    end
    return true
  end
end
