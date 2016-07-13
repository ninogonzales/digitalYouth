# --------------- Imports ---------------
from lxml import html
from lxml.html.clean import clean_html
import nltk.data
import requests
import os
import sys
import time
from lxml import etree
# --------------- Functions ---------------
def add_skills(skill_str,arr):
	tokenizer = nltk.data.load('tokenizers/punkt/english.pickle')
	if skill_str is not None:
		skill_str = skill_str.lower()
		skill_str = skill_str.strip().replace("\"", "").replace(";", "")
		if not skill_str == "":
			if len(skill_str) > 300:
				tokens = tokenizer.tokenize(skill_str)
				for token in tokens:
					if len(token) < 400:
						arr.append(check_string(token))
			else:
				arr.append(check_string(skill_str))
	return arr

def check_string(string):
	if string.endswith('\\') or string.endswith(';'):
		return string[:-1]
	else:
		return string

def process(file,cnt,skill_cnt,companies,user_cnt):
	try:
		tree = html.fromstring(open(file, "r").read())
		logo = tree.xpath('//a[@class="job-view-company-logo-link"]/img/@src')
		company_name = tree.xpath('//span[@data-automation="job-company"]')[0].text.title()
		title = tree.xpath('//*[@data-automation="job-title"]')[0].text.title()
		loc_arr = tree.xpath('//*[@data-automation="job-Location"]')[0].text.title().split(',')
		location = loc_arr[0] + "," + loc_arr[1].upper()
		closing = ""
		link = tree.xpath('//*[@class="page-link"]/@href')[0]
		category = tree.xpath('//a[@class="job-view-header-link link"]')[0].text.title()
		req_skills = []
		pref_skills = []
		desc = []
		skip = False
		skills_strings = ['qualif','skill','abil,','able','capab','experi','criter','knowl','educ','']
		prefer_strings = ['prefer','good','nice','bonus','addit']

		tags = tree.xpath('//section[@class="job-view-content-wrapper js-job-view-header-apply"]/*')
		for p in tags:
			ptext = "".join(p.itertext())
			if any(substr in ptext.lower() for substr in skills_strings): #and not in responibility strings
				sibling = p.getnext()
				if sibling is not None:
					if sibling.tag == "ul":
						children = sibling.getchildren()
						for c in children:
							if not c == "\n":
								if any(substr in ptext.lower() for substr in prefer_strings):
									pref_skills = add_skills(c.text,pref_skills)
								else:
									req_skills = add_skills(c.text,req_skills)

			elif "closing" in ptext.lower() and "date" in ptext.lower() and len(ptext) < 50:
				closing = ptext
			# Can add condition here to get requirements too

			if len(ptext) > 100:
				ptext = ptext.replace("\r\n"," ").replace("\xa0"," ")
				if not any(substr in ptext.lower() for substr in req_skills) and not any(substr in ptext.lower() for substr in pref_skills):
					desc.append(ptext)

		desc = ''.join(desc)

		company_name = check_string(company_name.strip().replace("\"", ""))
		title = check_string(title.strip().replace("\"", ""))
		location = check_string(location.strip().replace("\"", ""))
		closing = check_string(closing.strip().replace("\"", ""))
		desc = check_string(desc.strip().replace("\"", ""))

		create_job = "jobposting"+str(cnt)+" = JobPosting.create("
		create_user = "user" + str(user_cnt) + " = create_random_user("
		line = "\n"

		if req_skills == [] or desc == "":
			return ""

		if company_name not in companies:
			companies[company_name] = user_cnt
			line += create_user+ "\""+company_name+"\")\n"
			user_cnt += 1

		line += "jobcategory"+str(cnt)+" = create_category(\""+category+"\")\n"

		line += create_job + "title: \""+title+"\","
		line += "" if desc == "" or "<" in desc else "description: \""+desc+"\","
		line += "location: \""+location +"\","
		line += "link: \""+link+"\","
		line += "job_category_id: "+"JobCategory"+str(cnt)+".id,"
		line += "" if closing == "" else "close_date: \"" + closing + "\","
		line += "user_id: User"+str(companies[company_name])+".id)"
		line += "\n"

		for s in req_skills:
			line += "skill"+str(skill_cnt)+" = create_skill(\""+s+"\")\n"
			line += "jobpostingskill"+str(skill_cnt)+" = JobPostingSkill.create(skill_id: Skill"+str(skill_cnt)+".id,job_posting_id: JobPosting"+str(cnt)+".id,importance:2)\n"
			skill_cnt += 1
		for s in pref_skills:
			line += "skill"+str(skill_cnt)+" = create_skill(\""+s+"\")\n"
			line += "jobpostingskill"+str(skill_cnt)+" = JobPostingSkill.create(skill_id: Skill"+str(skill_cnt)+".id,job_posting_id: JobPosting"+str(cnt)+".id,importance:1)\n"
			skill_cnt += 1
		line += "\n"
		if "skill" not in line:
			return ""
		return [line,skill_cnt,companies,user_cnt]
	except (IndexError, etree.XMLSyntaxError):
		return ""

def startProgress(title):
    global progress_x
    sys.stdout.write(title + ": [" + " "*40 + "]" + chr(8)*41)
    sys.stdout.flush()
    progress_x = 0

def progress(x):
    global progress_x
    x = int(x * 40 // 100)
    sys.stdout.write("-" * (x - progress_x))
    sys.stdout.flush()
    progress_x = x

def endProgress():
    sys.stdout.write("-" * (40 - progress_x) + "]\n")
    sys.stdout.flush()


# ---------------------------------------
path = os.path.realpath(__file__).strip(__file__)
os.chdir(path)
print("----------- File Processor -----------\n")
print("Ensure the path below contains the file processor:")
print(path)
print("If it doesn't then cd to the correct path and run again.\n")

categories = ["Arts, Media and Entertainment","Technology and Digital Media"]
print("----------- Categories -----------")
num = 0 # input number
for c in categories:
	print("[" + str(num) + "] " + c)
	num = num+1
print("----------------------------------")

cat_path = ""
while True:
	cat = input('\nChoose an above Category to process or enter one: ')
	try:
		cat = categories[int(cat)]
	except ValueError:
		cat = cat

	cat_path = "/data/categories/" + cat
	try:
		os.chdir(path+cat_path)
		break
	except FileNotFoundError:
		print("Directory Not Found")
print("----------------------------------")

os.chdir(path)
file = open("job_posting_seeds_"+cat+".rb", 'w')
file.write("puts \"Seeding Job Postings for: "+cat+"\"\n")
path+=cat_path
os.chdir(path)

companies = {}
user_cnt = 0
cnt = 0
pointer = 0
num_files = 0
skill_cnt = 0
subdirs = [x[0] for x in os.walk(path)]
del subdirs[0]

for subdir in subdirs:
	num_files += len([f for f in os.listdir(subdir) if os.path.isfile(os.path.join(subdir, f))])
num_files -= len(subdirs) + 1

startProgress("Processing")
for subdir in subdirs:
	os.chdir(subdir)
	for file_name in os.listdir(subdir):
		rtns = process(file_name,cnt,skill_cnt,companies,user_cnt)
		try:
			if not rtns[0] == "":
				progress((pointer/num_files)*100)
				file.write(rtns[0] + "\n")
				skill_cnt = rtns[1]
				companies = rtns[2]
				user_cnt = rtns[3]
				cnt += 1
		except IndexError:
			do_nothing = True
		pointer += 1
endProgress()
print(str(cnt)+" Files Successfully Processed.")