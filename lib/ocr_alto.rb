require 'nokogiri'

module OcrAlto

  MARGIN = 50

  # box1 overlaps box2
  def self.overlap(box1, box2)
  	! (box1[:hpos] + box1[:width] < box2[:hpos] ||
  		 box1[:hpos] > box2[:hpos] + box2[:width] ||
  		 box1[:vpos] + box1[:height] < box2[:vpos] ||
  		 box1[:vpos] > box2[:vpos] + box2[:height])
  end

  # box1 encloses box2
  def self.enclose(box1, box2)
  	box1[:hpos] - MARGIN  <= box2[:hpos] &&
  	box1[:hpos] + box1[:width] + MARGIN >= box2[:hpos] + box2[:width] &&
  	box1[:vpos] - MARGIN <= box2[:vpos] &&
  	box1[:vpos] + box1[:height] + MARGIN >= box2[:vpos] + box2[:height]
  end

  # extract ORC text inside of box from the ALTO file
  # box should have keys such as hpos, vpos, width, height
  # values are normalized to image with width = 1 and height = 1
  def self.extract_text_from_alto(alto_url, nbox)
  	text = ""
  	doc = Nokogiri::XML(open(alto_url))
	  # ALTO XMLs may have inconsistent namespaces
	  doc.remove_namespaces!

	  page = doc.xpath("//Page").first
	  page_width = page['WIDTH'].to_i
	  page_height = page['HEIGHT'].to_i

	  box = {
	  	hpos: nbox[:hpos] * page_width,
	  	vpos: nbox[:vpos] * page_height,
	  	width: nbox[:width] * page_width,
	  	height: nbox[:height] * page_height,
	  }

	  doc.xpath("//TextBlock").each do |tb|
	  	if overlap({hpos:tb['HPOS'].to_f, vpos:tb['VPOS'].to_f, width:tb['WIDTH'].to_f, height:tb['HEIGHT'].to_f}, box)
		    tb.xpath(".//String").each do |str|
		    	if enclose(box, {hpos: str['HPOS'].to_f, vpos: str['VPOS'].to_f, width: str['WIDTH'].to_f, height: str['HEIGHT'].to_f})
		    		text << " " << str['CONTENT']
		    	end
		    end
		  end
		  text = text.strip
		  text << "\n"
	  end # doc.xpath("//TextBlock").each
	  text.strip
  end

end