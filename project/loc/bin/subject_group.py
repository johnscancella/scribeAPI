import sys
import getopt
import requests
import lxml.etree
from StringIO import StringIO

CHRONAM_URL = 'http://chroniclingamerica.loc.gov'


# create a group file named group_[lccn]_[year].csv
def create_group_file(lccn, year):
    file_name = "group_%s_%s.csv" % (lccn, str(year))
    f = open(file_name, 'w+')
    f.write('order,page_url,file_path,thumbnail,width,height,alto\n')
    order = 0
    for page in _title_pages(lccn, year):
        try:
            order += 1
            page_base_url = page[0:-5] # remove trailing ".json"
            width, height = _page_dimensions(page_base_url)
            image_url = "%s/image_%dx%d.jpg" % (page_base_url, width, height)
            thumbnail_url = "%s/thumbnail.jpg" % page_base_url
            alto_url = "%s/ocr.xml" % page_base_url
            f.write("%d,%s,%s,%s,%d,%d,%s\n"
                    % (order, page_base_url, image_url, thumbnail_url,
                        width, height, alto_url))
        except:
            e = sys.exc_info()[1]
            print "failed to process page %s, reason %s", page, e

    f.close()

def _title_pages(lccn, year):
    title_url = "%s/lccn/%s.json" % (CHRONAM_URL, lccn)
    r = requests.get(title_url)
    title = r.json()
    issue_year = str(year)
    issues = [issue['url'] for issue in title['issues']
              if issue['date_issued'].startswith(issue_year)]
    pages = []
    for issue in issues:
        pages.extend(_issue_pages(issue))
    return pages


def _issue_pages(issue_url):
    r = requests.get(issue_url)
    issue = r.json()
    return [page['url'] for page in issue['pages']]

def _page_dimensions(page_base_url):
    # the original image in full resolution is too large
    # need to resize it
    RESIZE_FACTOR = 0.30
    rdf_url = "%s.rdf" % page_base_url
    r = requests.get(rdf_url)
    parser = lxml.etree.XMLParser(load_dtd=False,
                                  dtd_validation=False, recover=True)
    xml = lxml.etree.parse(StringIO(r.content), parser).getroot()
    namespaces = {'rdf': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                  'exif': 'http://www.w3.org/2003/12/exif/ns#'}
    width = xml.xpath('/rdf:RDF/rdf:Description/exif:width/text()', namespaces=namespaces)[0]
    height = xml.xpath('/rdf:RDF/rdf:Description/exif:height/text()', namespaces=namespaces)[0]
    return int(round(int(width)*RESIZE_FACTOR)), int(round(int(height)*RESIZE_FACTOR))


def main(argv):
   lccn = None
   year = None
   try:
      opts, args = getopt.getopt(argv,"hl:y:",["lccn=","year="])
   except getopt.GetoptError:
      print 'subject_group.py -l <lccn> -y <year>'
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print 'subject_group.py -l <lccn> -y <year>'
         sys.exit()
      elif opt in ("-l", "--lccn"):
         lccn = arg
      elif opt in ("-y", "--year"):
         year = arg
   print 'Creating subject group file for LCCN %s, year %s' % (lccn, year)
   create_group_file(lccn, year)
   print 'Complete!'

if __name__ == "__main__":
   main(sys.argv[1:])
