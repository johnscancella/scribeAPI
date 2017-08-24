'''
This script read a CSV file that contains chronam newspaper pages info
and creates a group file for each State. It also create groups.csv file

Example: python create_subjects_from_csv.py ww1_pages.csv
'''

import csv
import sys
import re
import urllib
import os.path
import us

CHRONAM_URL = 'http://chroniclingamerica.loc.gov'
RESIZE_FACTOR = 0.25

MONTH_NAMES = {1: "January",
                  2: "February",
                  3: "March",
                  4: "April",
                  5: "May",
                  6: "June",
                  7: "July",
                  8: "August",
                  9: "September",
                  10: "October",
                  11: "November",
                  12: "December"}

STATE_COVER_IMAGE_URL = 'https://s3.amazonaws.com/beyond-words-images/flags/%s.png'


def create_subject_files(csv_reader):
    group_file_count = {}

    for page in csv_reader:
        if page['jp2_filename'] == 'NULL':
            continue
        group_filename = _group_filename(page['state'])
        file_exist = os.path.isfile(group_filename)
        with open(group_filename, 'a') as f:
            if not file_exist:
                group_file_count[group_filename] = 0
                f.write('order,subject_url,subject_description,resize,file_path,thumbnail,width,height,alto\n')
                _write_group_file(unicode(page['state']))
            group_file_count[group_filename] += 1
            issue_date = page['issue_date'].split('/')
            month = int(issue_date[0])
            day = int(issue_date[1])
            year = int(issue_date[2])
            subject_url = '%s/lccn/%s/%d-%02d-%02d/ed-%s/seq-%s/' % (
                CHRONAM_URL, page['lccn'], year, month, day, page['edition'], page['sequence'])
            description = "%s %s. Page %s" % (page['title'], _format_date(year, month, day), page['sequence'])
            width = int(round(int(page['jp2_width'])*RESIZE_FACTOR))
            height = int(round(int(page['jp2_length'])*RESIZE_FACTOR))
            image_url = "%simage_%dx%d.jpg" % (subject_url, width, height)
            thumbnail_url = "%sthumbnail.jpg" % subject_url
            alto_url = "%socr.xml" % subject_url
            f.write('%d,"%s","%s",%f,"%s","%s",%d,%d,"%s"\n'
                    % (group_file_count[group_filename], subject_url,
                        description, RESIZE_FACTOR, image_url, thumbnail_url,
                        width, height,
                        alto_url))


def _write_group_file(state):
    groups_filename = "groups.csv"
    file_exist = os.path.isfile(groups_filename)
    with open(groups_filename, 'a') as f:
        if not file_exist:
            f.write('key,name,description,cover_image_url,external_url\n')
        group_key = "%s" % (_cleanse_state_name(state))
        name = "%s" % state
        description = "Historic Newspapers from %s" % state

        cover_image_url = STATE_COVER_IMAGE_URL % (us.states.lookup(state).abbr.lower())
        search_param = {
            'state': state
        }
        external_url = "%s/search/pages/results/?%s" % (CHRONAM_URL, urllib.urlencode(search_param))
        f.write('%s,"%s","%s","%s","%s"\n'
                % (group_key, name, description, cover_image_url,
                    external_url))


def _format_date(year, month, day):
    '''
    format as Month day, Year
    '''
    return "%s %02d, %d" % (MONTH_NAMES[month], day, year)


def _cleanse_state_name(state):
    state = state.lower()
    state = re.sub(r"[^\w\s]", '', state)
    return re.sub(r"\s+", '-', state)


def _group_filename(state):
    state = _cleanse_state_name(state)
    return "group_%s.csv" % (state)


def main(file_name):
    print file_name
    with open(file_name, 'rb') as csvfile:
        csv_reader = csv.DictReader(csvfile)
        create_subject_files(csv_reader)

if __name__ == "__main__":
    main(sys.argv[1])
