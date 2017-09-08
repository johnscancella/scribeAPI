'''
This script read a CSV file that contains chronam newspaper pages info
and creates a group file for each State. It also create groups.csv file

Example: python create_subjects_tsv.py ww1_pages.tsv
'''

import csv
import sys
import re
import urllib
import os
import os.path
import us

import boto3
import botocore

CHRONAM_URL = 'http://chroniclingamerica.loc.gov'
IMAGE_S3_BUCKET = 'ndnp-jpeg-surrogates'
OCR_S3_BUCKET = 'ndnp-batches'
# full resolution
RESIZE_FACTOR = 1

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

s3 = boto3.resource('s3')

missing_images = 0
processed_images = 0


class S3ImageBucket:

    def __init__(self):
        self.loaded_batches = set()
        self.missing_batches = set()

    def image_exists_on_s3(self, image_obj_path):
        batch = image_obj_path.split('/')[0]
        if batch in self.missing_batches:
            return False
        if batch in self.loaded_batches:
            return True
        # first time we see this batch
        if self._image_exists_on_s3(image_obj_path):
            self.loaded_batches.add(batch)
            print "Batch exists on S3: %s" % batch
            return True
        else:
            self.missing_batches.add(batch)
            print "Batch missing on S3: %s" % batch
            return False

    def _image_exists_on_s3(self, image_obj_path):
        return self._exists_on_s3(IMAGE_S3_BUCKET, image_obj_path)

    def _exists_on_s3(self, bucket, obj_path):
        try:
            s3.Object(bucket, obj_path).load()
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] == "404":
                return False
            else:
                raise
        return True

    def report(self):
        print "Missing %d batches: %s" % (len(self.missing_batches), self.missing_batches)
        print "Loaded %d batches: %s" % (len(self.loaded_batches), self.loaded_batches)

s3_image_bucket = S3ImageBucket()

def _image_url(batch, jp2_filename):
    return "http://s3.amazonaws.com/%s/%s" % (IMAGE_S3_BUCKET, _image_obj_path(batch, jp2_filename))

def _image_obj_path(batch, jp2_filename):
    if batch.startswith('batch_'):
        batch = batch[6:]
    image_base = os.path.splitext(jp2_filename)[0]
    return "%s/data/%s.jpg" % (batch, image_base)

def _ocr_url(batch, ocr_filename):
    if batch.startswith('batch_'):
        batch = batch[6:]
    return "http://s3.amazonaws.com/%s/%s/data/%s" % (OCR_S3_BUCKET, batch, ocr_filename)

def create_subject_files(csv_reader):
    global missing_images, processed_images
    group_file_count = {}

    for page in csv_reader:
        if page['jp2_filename'] == 'NULL':
            continue
        group_filename = _group_filename(page['state'])
        file_exist = os.path.isfile(group_filename)
        with open(group_filename, 'a') as f:
            if not file_exist:
                group_file_count[group_filename] = 0
                f.write('order,set_key,subject_url,subject_description,resize,file_path,thumbnail,width,height,alto\n')
                _write_group_file(unicode(page['state']))
            subject_url = '%s/lccn/%s/%s/ed-%s/seq-%s/' % (
                CHRONAM_URL, page['lccn'], page['issue_date'], page['edition'], page['sequence'])
            description = "%s %s. Page %s" % (page['title'], _format_date(page['issue_date']), page['sequence'])
            width = int(round(int(page['jp2_width'])*RESIZE_FACTOR))
            height = int(round(int(page['jp2_length'])*RESIZE_FACTOR))
            image_url = _image_url(page['batch'], page['jp2_filename'])
            thumbnail_url = "%sthumbnail.jpg" % subject_url
            alto_url = _ocr_url(page['batch'], page['ocr_filename'])
            # make sure it exists on S3
            if s3_image_bucket.image_exists_on_s3(_image_obj_path(page['batch'], page['jp2_filename'])):
                group_file_count[group_filename] += 1
                f.write('%d,"%s","%s","%s",%f,"%s","%s",%d,%d,"%s"\n'
                        % (group_file_count[group_filename], subject_url, subject_url,
                            description, RESIZE_FACTOR, image_url, thumbnail_url,
                            width, height,
                            alto_url))
            else:
                missing_images += 1

            processed_images += 1
            if processed_images % 1000 == 0:
                print "Processed images: %d" % processed_images




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


def _format_date(issue_date):
    '''
    format as Month day, Year
    '''
    issue_date = issue_date.split('-')
    return "%s %s, %s" % (MONTH_NAMES[int(issue_date[1])], issue_date[2], issue_date[0])


def _cleanse_state_name(state):
    state = state.lower()
    state = re.sub(r"[^\w\s]", '', state)
    return re.sub(r"\s+", '-', state)


def _group_filename(state):
    state = _cleanse_state_name(state)
    return "group_%s.csv" % (state)


def main(file_name):
    global missing_images
    with open(file_name, 'rb') as csvfile:
        csv_reader = csv.DictReader(csvfile, delimiter='\t')
        create_subject_files(csv_reader)
    print "Total number of missing images: %d" % missing_images
    s3_image_bucket.report()

if __name__ == "__main__":
    main(sys.argv[1])
