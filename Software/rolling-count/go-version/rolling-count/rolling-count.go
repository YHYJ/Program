/* File: rolling-count.go */
/* Author: YJ */
/* Email: yj1516268@outlook.com */
/* Created Time: 2023-02-15 10:24:11 */

// Description:

package main

import (
	"bufio"
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"
)

var fileName = "/var/log/pacman.log"

// 读取文件指定行
func ReadFileLine(file string, line int) string {
	// 打开文件
	text, err := os.Open(file)
	// 相当于Python的with语句
	defer text.Close()
	// 处理错误
	if err != nil {
		log.Fatal(err)
	}
	// 行计数
	count := 1
	// 创建一个扫描器对象按行遍历
	scanner := bufio.NewScanner(text)
	// 逐行读取，输出指定行
	for scanner.Scan() {
		if line == count {
			return scanner.Text()
		}
		count++
	}
	return ""
}

// 读取文件包含指定字符串的行
func ReadFileKey(file, key string) string {
	// 打开文件
	text, err := os.Open(file)
	// 相当于Python的with语句
	defer text.Close()
	// 处理错误
	if err != nil {
		log.Fatal(err)
	}
	// 创建一个扫描器对象按行遍历
	scanner := bufio.NewScanner(text)
	// 逐行读取，输出指定行
	for scanner.Scan() {
		if strings.Contains(scanner.Text(), key) {
			return scanner.Text()
		}
	}
	return ""
}

// 获取文件包含指定字符串的行的计数
func ReadFileCount(file, key string) int {
	// 打开文件
	text, err := os.Open(file)
	// 相当于Python的with语句
	defer text.Close()
	// 处理错误
	if err != nil {
		log.Fatal(err)
	}
	// 计数器
	count := 0
	// 创建一个扫描器对象按行遍历
	scanner := bufio.NewScanner(text)
	// 逐行读取，输出指定行
	for scanner.Scan() {
		if strings.Contains(scanner.Text(), key) {
			count++
		}
	}
	return count
}

// 运行指定命令
func RunCommand(command, args string) string {
	// 定义命令
	cmd := exec.Command(command, args)

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout // 标准输出
	cmd.Stderr = &stderr // 标准错误

	// 执行命令获取输出
	err := cmd.Run()
	outStr, errStr := string(stdout.Bytes()), string(stderr.Bytes())

	if err != nil {
		log.Fatalf("Run failed with %s\n", errStr)
	}

	return strings.TrimRight(outStr, "\n")
}

// 获取系统安装时间和当前时间
var lineText = ReadFileLine(fileName, 1)
var startTimeStrLong = strings.Split(lineText, " [")[0]
var startTimeStr = strings.Split(strings.Split(lineText, "[")[1], "]")[0]
var currentTimeStr = time.Now().Format("2006-01-02 15:04")

// 获取初始和当前内核版本
var keyText = ReadFileKey(fileName, "upgraded linux ")
var firstKernel = strings.Split(strings.Split(keyText, " (")[1], " ")[0]
var latestKernel = RunCommand("uname", "-r")

// 计算系统安装天数
var local, _ = time.LoadLocation("Asia/Shanghai")
var startTime, _ = time.ParseInLocation("2006-01-02 15:04", startTimeStr, local)
var startTimeStamp = startTime.Unix()
var currentTime, _ = time.ParseInLocation("2006-01-02 15:04", currentTimeStr, local)
var currentTimeStamp = currentTime.Unix()
var systemDays = (currentTimeStamp - startTimeStamp) / 86400

// 获取系统/内核更新相关数据
var systemUpdateCount = ReadFileCount(fileName, "starting full system upgrade")
var systemUpdateMean = float32(systemUpdateCount) / float32(systemDays)
var kernelUpdateCount = ReadFileCount(fileName, "upgraded linux ")
var kernelUpdateMean = float32(systemDays) / float32(kernelUpdateCount)

// 获取吉祥物
var mascot = RunCommand("repo-elephant", "")

func main() {
	fmt.Printf("[%16v] %-2v [%-16v]\n", startTimeStr, "--", currentTimeStr)
	fmt.Printf("%18v %-2v %-18v\n", firstKernel, "--", latestKernel)
	fmt.Printf("%12v %-2v %-4.3v %v\n", "系统使用时长", "--", systemDays, "天")
	fmt.Printf("%12v %-2v %-4.3v %v\n", "系统更新次数", "--", systemUpdateCount, "次")
	fmt.Printf("%12v %-2v %-4.3v %v\n", "系统更新频率", "--", systemUpdateMean, "次/天")
	fmt.Printf("%12v %-2v %-4.3v %v\n", "内核更新次数", "--", kernelUpdateCount, "次")
	fmt.Printf("%12v %-2v %-4.3v %v\n", "内核更新频率", "--", kernelUpdateMean, "天/次")
	fmt.Println(mascot)
}
