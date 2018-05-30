import pickle
import sys
from nltk.tokenize import LineTokenizer
file_name = sys.argv[1]
filename_and_extension = file_name.split('.')
without_extension = filename_and_extension[0]+"."+filename_and_extension[1]+"_tagged."+filename_and_extension[2]
count = 1
data = open(file_name, 'r').read()
list_of_data = LineTokenizer(blanklines='keep').tokenize(data)
sample_sentences = list_of_data[:]
tagged_corpus = open(without_extension, "a+")
tagger = pickle.load(open('/home/tsegaye/PycharmProjects/POS 2018/models/tnt_back_off.pkl', 'rb'))
for each_item in sample_sentences:
    tagged_sentence= tagger.tag(each_item.split())
    tagged_corpus.write(' '.join('{}|{}|{}'.format(x[0],x[0], x[1]) for x in tagged_sentence))
    tagged_corpus.write('\n')
    print(count)
    count += 1
print('tagging words finished')
tagged_corpus.close()