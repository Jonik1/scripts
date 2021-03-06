require "spec_helper"
require "open3"

describe "Command Retry Script" do

  it "retries the execution 3 times" do
    stdout, stderr, status = Open3.capture3("utility/retry false")

    msg = [
      "[1/3] Execution Failed with exit status 1. Retrying.",
      "[2/3] Execution Failed with exit status 1. Retrying.",
      "[3/3] Execution Failed with exit status 1. No more retries.",
      ""
    ].join("\n")

    expect(stdout).to eq(msg)
    expect(status.exitstatus).to eq(1)
  end

  it "preserves the exit status" do
    stdout, stderr, status = Open3.capture3("utility/retry timeout 0.1 sleep 10")

    msg = [
      "[1/3] Execution Failed with exit status 124. Retrying.",
      "[2/3] Execution Failed with exit status 124. Retrying.",
      "[3/3] Execution Failed with exit status 124. No more retries.",
      ""
    ].join("\n")

    expect(stdout).to eq(msg)
    expect(status.exitstatus).to eq(124) # test based on the fact that timeout has a specific exitstatus
  end

  describe "sleep option" do
    context "no sleep option passed" do
      it "doesn't nap" do
        started = Time.now
        Open3.capture3("utility/retry false")
        finished = Time.now

        expect(finished - started).to be < 1
      end
    end

    context "sleep option passed" do
      it "naps for the passed seconds between execution" do
        started = Time.now
        Open3.capture3("utility/retry --sleep 0.5 --times 4 false")
        finished = Time.now

        expect(finished - started).to be > 1
        expect(finished - started).to be < 3
      end
    end

  end

  describe "times option" do
    it "reties the passed number of times" do
      stdout, stderr, status = Open3.capture3("utility/retry --times 7 false")

      msg = [
        "[1/7] Execution Failed with exit status 1. Retrying.",
        "[2/7] Execution Failed with exit status 1. Retrying.",
        "[3/7] Execution Failed with exit status 1. Retrying.",
        "[4/7] Execution Failed with exit status 1. Retrying.",
        "[5/7] Execution Failed with exit status 1. Retrying.",
        "[6/7] Execution Failed with exit status 1. Retrying.",
        "[7/7] Execution Failed with exit status 1. No more retries.",
        ""
      ].join("\n")

      expect(stdout).to eq(msg)
    end
  end

  context "when the command contains complex bash logic" do
    it "can use the retry script if the commands are passed as a string" do
      stdout, stderr, status = Open3.capture3("utility/retry --times 3 'for i in {1..2}; { echo $i; }; false'")

      expect(status.exitstatus).to eq(1)

      expect(stdout).to eq([
        "1",
        "2",
        "[1/3] Execution Failed with exit status 1. Retrying.",
        "1",
        "2",
        "[2/3] Execution Failed with exit status 1. Retrying.",
        "1",
        "2",
        "[3/3] Execution Failed with exit status 1. No more retries.",
        ""
      ].join("\n"))
    end
  end

end
