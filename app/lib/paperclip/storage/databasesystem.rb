module Paperclip
  module Storage
    module Databasesystem
      def self.extended base
      end

      def exists?(style_name = default_style)
        if original_filename
          File.exist?(path(style_name))
        else
          false
        end
      end

      def url(style_name)
        s = super(style_name)
        if (use_account_db)
          local_path = path(style_name)
          if ((local_path != nil) && !File.exists?(local_path))
            a = Account.find(@instance.id)
            File.binwrite(local_path, a.image_binary_original)
          end
        end
        return s
      end

      def flush_writes #:nodoc:
        # @instance.class.nameを確認
        # @instance.class.methodsで対象のフィールドがあるか確認
        # @instance.idでaccountsを検索
        # 対象のフィールドへバイナリ化した画像を書き込む
        # accounts -> styleはoriginalのみ
        # media_attachments -> originalとsmall
        @queued_for_write.each do |style_name, file|
          if (use_account_db)
            a = Account.find(@instance.id)
            a.image_binary_original = file.read
            a.save!
          end
          FileUtils.mkdir_p(File.dirname(path(style_name)))
          begin
            FileUtils.mv(file.path, path(style_name))
          rescue SystemCallError  #エラー時はファイルをコピー
            File.open(path(style_name), "wb") do |new_file|
              while chunk = file.read(16 * 1024)
                new_file.write(chunk)
              end
            end
          end
          unless @options[:override_file_permissions] == false
            resolved_chmod = (@options[:override_file_permissions] &~ 0111) || (0666 &~ File.umask)
            FileUtils.chmod( resolved_chmod, path(style_name) )
          end
          file.rewind
        end

        after_flush_writes # allows attachment to clean up temp files

        @queued_for_write = {}
      end

      def flush_deletes #:nodoc:
        @queued_for_delete.each do |path|
          begin
            log("deleting #{path}")
            FileUtils.rm(path) if File.exist?(path)
          rescue Errno::ENOENT => e
            # ignore file-not-found, let everything else pass
          end
          begin
            while(true)
              path = File.dirname(path)
              FileUtils.rmdir(path)
              break if File.exist?(path) # Ruby 1.9.2 does not raise if the removal failed.
            end
          rescue Errno::EEXIST, Errno::ENOTEMPTY, Errno::ENOENT, Errno::EINVAL, Errno::ENOTDIR, Errno::EACCES
            # Stop trying to remove parent directories
          rescue SystemCallError => e
            log("There was an unexpected error while deleting directories: #{e.class}")
            # Ignore it
          end
        end
        @queued_for_delete = []
      end

      def copy_to_local_file(style, local_dest_path)
        p "-------------------------------"
        p "copy_to_local_file"
        p "-------------------------------"
        if (use_account_db)
          a = Account.find(@instance.id)
          File.binwrite(local_dest_path, a.image_binary_original)
        else
          FileUtils.cp(path(style), local_dest_path)
        end
      end

      private
      def use_account_db
        if @instance.class.name == "Account"
          if @instance.class.column_names.include?("image_binary_original")
            return true
          end
          return false
        end
      end
    end
  end
end
