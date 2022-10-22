#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
File: pic-conver.py
Author: YJ
Email: yj1516268@outlook.com
Created Time: 2021-11-10 16:11:38

Description: 读取原图片信息，转换为指定大小格式的图片

Depends:
- Pillow

TODO:
- 将转换结果放到原始图片同意路径下
- 要求用户输入时允许其使用Tab键补全路径
- 加上参数
- 输入类型判断
- 不识别符号例如'~'
"""

from PIL import Image

# 目标图片存储地址
save_path = '/home/yj/Pictures'
# 目标图片默认名
pic_name = 'Conversion_results'
# 允许的目标图片格式
mode_list = ['jpg', 'png', 'bmp']

picture_path = input('请输入图片的绝对路径：')
image = Image.open(picture_path)
print('原始图片类型：{}'.format(image.format))
print('原始图片尺寸：{}'.format(str(image.size[0]) + '*' + str(image.size[1])))
print('原始图片格式：{}\n'.format(image.mode))

print('转换开始>>>')
picture_lsize = int(input('请输入目标图片的长度：'))
picture_wsize = int(input('请输入目标图片的宽度：'))
picture_mode = input('请输入目标图片的类型({})：'.format(','.join(mode_list))).lower()

image.thumbnail((picture_lsize, picture_wsize))
if picture_mode in mode_list:
    if picture_mode == 'jpg':
        mode = 'jpeg'
        image.save(
            '{path}/{name}.{suffix}'.format(path=save_path,
                                            name=pic_name,
                                            suffix=picture_mode), mode)
    else:
        image.save(
            '{path}/{name}.{suffix}'.format(path=save_path,
                                            name=pic_name,
                                            suffix=picture_mode), picture_mode)
    print('\n目标图片地址：{path}/{name}.{suffix}'.format(path=save_path,
                                                   name=pic_name,
                                                   suffix=picture_mode))
