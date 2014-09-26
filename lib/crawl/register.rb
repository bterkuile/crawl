class Crawl::Register

  Result = Struct.new(:url, :object)

  def initialize
    @unprocessed = Set.new
    @processing = Set.new
    @processed = Set.new
  end

  def add(pages)
    new_pages = pages.to_set - @processed - @processing - @unprocessed
    new_pages.each do |new_page|
      puts "  Adding #{new_page.url}" if $verbose
    end
    @unprocessed.merge(new_pages)
  end

  def next_page
    page = @unprocessed.first
    @unprocessed.delete(page)
    @processing << page if page
    if @processing.size > EM.threadpool_size
      puts "WARNING: #{@processing.size} pages are being process when EM threadpool only has #{EM.threadpool_size} threads."
    end
    page
  end

  def retry(page)
    @unprocessed << page
    @processing.delete(page)
  end

  def completed(page)
    @processed << page
    @processing.delete(page)
  end

  def finished?
    @unprocessed.size + @processing.size == 0
  end

  def processing_size
    @processing.size
  end

  def error_pages
    @error_pages ||= @processed.select{ |page| page.error }
  end

  def query_pages
    @query_pages ||= @processed.select{ |page| page.query? }
  end

  def errors?
    !error_pages.empty?
  end

  def query_pages?
    !query_pages.empty?
  end

  def summarize
    if errors?
      puts "\n#{@processed.size} pages crawled."
      if query_pages?
        puts "\n Pages with query matching"
        query_pages.each do |page|
          puts page.to_s
        end
      end
      puts "\nPages with errors (#{error_pages.size}):"
      error_pages.each do |page|
        puts page.to_s
      end
    else
       puts "\n#{@processed.size} pages crawled without errors."
    end
  end

  def no_links_found?
    @processed.size <= 1
  end
end
