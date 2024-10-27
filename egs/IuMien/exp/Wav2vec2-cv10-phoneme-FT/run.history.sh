# train tokenizer and pickle data
# python utils/pipeline/asr.py exp/Wav2vec2-cv10-phoneme-FT --sta 1 --sto 2

# paper pretrain model
# you could download pt_tokenizer and pt_model from 
# https://github.com/thu-spmi/CAT/tree/master/egs/cv-lang10/exp/Multilingual/Wav2vec-lang10


# train model
# python utils/pipeline/asr.py exp/Wav2vec2-cv10-phoneme-FT --sta 3 --sto 3

# per test
# python utils/pipeline/asr.py exp/Wav2vec2-cv10-phoneme-FT --sta 4 --sto 4

# use wfst decode
# First, you need to modify the hyper-p.json file.
# "infer": {
#             "bin": "cat.ctc.cal_logit",
#             "option": {
#                 "beam_size": 32,
#                 "nj": 16,
#                 "store_ark": true
#             }
#         },
# python utils/pipeline/asr.py exp/Wav2vec2-cv10-phoneme-FT --sta 4 --sto 4
# bash exp/lexicon_wfst_run.sh --exp_dir exp/Wav2vec2-cv10-phoneme-FT --lm_dir exp/decode_lm  --dataset_name test_raw
