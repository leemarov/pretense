import sys
import os
import zipfile

buildpath = "build/"

if len(sys.argv) != 5:
    print("Invalid argument count")
    print("build.py [mist_filepath] [pretense_filepath] [miz_filepath] [init_filepath]")

mist_filepath = sys.argv[1]
pretense_filepath =sys.argv[2]
miz_filepath = sys.argv[3]
init_filepath = sys.argv[4]

os.makedirs(buildpath, exist_ok=True)
writepath = buildpath + os.path.basename(miz_filepath)

with zipfile.ZipFile(miz_filepath, 'r') as zip_in:
    with zipfile.ZipFile(writepath, 'w') as zip_out:
        zip_out.comment = zip_in.comment
        for item in zip_in.infolist():
            if item.filename in [
                "l10n/DEFAULT/pretense_compiled.lua",
                "l10n/DEFAULT/init.lua",
                "l10n/DEFAULT/mist_4_5_121_custom.lua"]:
                continue
            zip_out.writestr(item, zip_in.read(item.filename))
        zip_out.writestr("l10n/DEFAULT/pretense_compiled.lua", open(pretense_filepath, 'r').read())
        zip_out.writestr("l10n/DEFAULT/init.lua", open(init_filepath, 'r').read())
        zip_out.writestr("l10n/DEFAULT/mist_4_5_121_custom.lua", open(mist_filepath, 'r').read())