.PHONY: docs
docs: encryptroot.asahi.8.html encryptroot.asahi.8.md

encryptroot.asahi.8.html: encryptroot.asahi.8
	pandoc -o encryptroot.asahi.8.html encryptroot.asahi.8

encryptroot.asahi.8.md: encryptroot.asahi.8
	pandoc -t markdown_strict -o encryptroot.asahi.8.md encryptroot.asahi.8