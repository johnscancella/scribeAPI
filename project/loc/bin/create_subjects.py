'''
This script query Chronam with a date range and create group file for each
State. It also create groups.csv
'''

import sys
import getopt
import requests
import re
import urllib
import os.path
import lxml.etree
from StringIO import StringIO

CHRONAM_URL = 'http://chroniclingamerica.loc.gov'


def _titles():
    titles_url = "%s/newspapers.json" % CHRONAM_URL
    r = requests.get(titles_url)
    return r.json()["newspapers"]


def create_subject_files(from_date, to_date):
    group_file_count = {}
    titles = _titles()
    for title in titles:
        print "Process title %s" % title['title']
        title_pages = _title_pages(title['url'], from_date, to_date)
        if len(title_pages) > 0:
            group_filename = _group_filename(title['state'], from_date, to_date)
            file_exist = os.path.isfile(group_filename)
            with open(group_filename, 'a') as f:
                if not file_exist:
                    group_file_count[group_filename] = 0
                    f.write('order,subject_url,file_path,thumbnail,width,height,alto\n')
                    _write_group_file(title['state'], from_date, to_date, title_pages[0])
                for page in title_pages:
                    try:
                        group_file_count[group_filename] += 1
                        page_base_url = page[0:-5] # remove trailing ".json"
                        width, height = _page_dimensions(page_base_url)
                        image_url = "%s/image_%dx%d.jpg" % (page_base_url, width, height)
                        thumbnail_url = "%s/thumbnail.jpg" % page_base_url
                        alto_url = "%s/ocr.xml" % page_base_url
                        f.write("%d,%s,%s,%s,%d,%d,%s\n"
                                % (group_file_count[group_filename], page_base_url + "/", image_url, thumbnail_url,
                                    width, height, alto_url))
                    except:
                        e = sys.exc_info()[1]
                        print "failed to process page %s, reason %s", page, e


def _write_group_file(state, from_date, to_date, first_page):
    groups_filename = "groups.csv"
    file_exist = os.path.isfile(groups_filename)
    with open(groups_filename, 'a') as f:
        if not file_exist:
            f.write('key,name,description,cover_image_url,external_url\n')
        group_key = "%s_%s_%s" % (_cleanse_state_name(state),
                                  from_date, to_date)
        name = "%s" % state
        description = "Historic Newspapers from %s" % state
        cover_image_url = "%s/image_512x512_from_0,0_to_5000,1000.jpg" % (first_page[0:-5])
        search_param = {
            'state': state
        }
        external_url = "%s/search/pages/results/?%s" % (CHRONAM_URL, urllib.urlencode(search_param))
        f.write('%s,"%s","%s","%s","%s"\n'
                % (group_key, name, description, cover_image_url,
                    external_url))

def _convert_date(date):
    '''
    convert from YYYY-MM-DD to MM/DD/YYYY
    '''
    year = date[0:4]
    month = date[5:7]
    day = date[8:10]
    return "%s/%s/%s" % (month, day, year)


def _cleanse_state_name(state):
    state = state.lower()
    state = re.sub(r"[^\w\s]", '', state)
    return re.sub(r"\s+", '-', state)


def _group_filename(state, from_date, to_date):
    state = _cleanse_state_name(state)
    return "group_%s_%s_%s.csv" % (state, from_date, to_date)


def _title_pages(title_url, from_date, to_date):
    r = requests.get(title_url)
    title = r.json()
    issues = [issue['url'] for issue in title['issues']
              if issue['date_issued'] >= from_date and
              issue['date_issued'] <= to_date]
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
    RESIZE_FACTOR = 0.25
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
    from_date = None
    to_date = None
    try:
        opts, args = getopt.getopt(argv,"hf:t:",["from=","to="])
    except getopt.GetoptError:
        print 'create_subjects.py -f <YYYY-MM-DD> -t <YYYY-MM-DD>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'create_subjects.py -f <YYYY-MM-DD> -t <YYYY-MM-DD>'
            sys.exit()
        elif opt in ("-f", "--from"):
            from_date = arg
        elif opt in ("-t", "--to"):
            to_date = arg
    if not from_date:
        print 'from date (-f, --from=) is required'
        sys.exit(2)
    if not to_date:
        print 'to date (-t, --to=) is required'
        sys.exit(2)

    print 'Creating subject files from %s to %s' % (from_date, to_date)
    create_subject_files(from_date, to_date)
    print 'Complete!'

if __name__ == "__main__":
    main(sys.argv[1:])
