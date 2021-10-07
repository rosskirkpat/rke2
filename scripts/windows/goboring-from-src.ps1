# https://go-boringcrypto.storage.googleapis.com/go1.16.7b7.src.tar.gz
$GOARCH = "amd64"
$GOOS = "windows"
$CGO_ENABLED = 1
$GOROOT_BOOTSTRAP = "C:\Program Files\Go"
$GOROOT = "C:\Program Files\Go"
$GOPATH = "C:\Users\rosskirk\go"
C:\Users\rosskirk\go


git clone https://github.com/rosskirkpat/go.git --track dev.boringcrypto.go1.16

go get github.com/rosskirkpat/go@dev.boringcrypto.go1.16

# alt to: go build -o /cmd/dist/dist.exe ./cmd/dist
# >go build -o /cmd/dist/dist.exe ./cmd/dist
# main module (std) does not contain package std/cmd/dist
push-location src/cmd/dist  
go build 
Pop-Location

.\cmd\dist\dist.exe env -w -p >env.bat
call env.bat
