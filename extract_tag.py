import sys
from nltk.corpus.reader import TaggedCorpusReader
from nltk.tokenize import LineTokenizer
filename  = sys.argv[1]
without_extension = filename.split('.')
file_address = filename.split('/')
directory = file_address[:-1]
directory_address = '/'.join('{}'.format(x) for x in directory) + '/'
corpus_reader = TaggedCorpusReader(directory_address,[filename], sent_tokenizer=LineTokenizer(), sep='|')
corpus = corpus_reader.tagged_sents()
new_tags_only = open(without_extension[0] + '_tag_sets.' + without_extension[1],'a+')
count = 1
for each in corpus:
    new_tags_only.write(' '.join('{}'.format(x[1]) for x in each))
    new_tags_only.write('\n')
    print(count)
    count += 1
print(without_extension[1] + "Tag extracting finished")
new_tags_only.close()
