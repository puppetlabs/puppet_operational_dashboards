# Contributing to Puppet modules

So you want to contribute to a Puppet module: Great! Below are some instructions to get you started doing
that very thing while setting expectations around code quality as well as a few tips for making the
process as easy as possible.

### Table of Contents

1.  [Getting Started](#getting-started)
2.  [Commit Checklist](#commit-checklist)
3.  [Submission](#submission)
4.  [More about commits](#more-about-commits)
5.  [Testing](#testing)
    -   [Running Tests](#running-tests)
    -   [Writing Tests](#writing-tests)
6.  [Get Help](#get-help)

## Getting Started

-   Fork the module repository on GitHub and clone to your workspace

-   Make your changes!

## Commit Checklist

### The Basics

-   [x] my commit is a single logical unit of work

-   [x] I have checked for unnecessary whitespace with "git diff --check"

-   [x] my commit does not include commented out code or unneeded files

### The Content

-   [x] my commit includes tests for the bug I fixed or feature I added

-   [x] my commit includes appropriate documentation changes if it is introducing a new feature or changing existing functionality

-   [x] my code passes existing test suites

### The Commit Message

-   [x] the first line of my commit message includes:

    -   [x] an issue number (if applicable), e.g. "(MODULES-xxxx) This is the first line"

    -   [x] a short description (50 characters is the soft limit, excluding ticket number(s))

-   [x] the body of my commit message:

    -   [x] is meaningful

    -   [x] uses the imperative, present tense: "change", not "changed" or "changes"

    -   [x] includes motivation for the change, and contrasts its implementation with the previous behavior

## Submission

### Pre-requisites

-   Make sure you have a [GitHub account](https://github.com/join)

-   [Create a ticket](https://tickets.puppet.com/secure/CreateIssue!default.jspa), or [watch the ticket](https://tickets.puppet.com/browse/) you are patching for.

### Push and PR

-   Push your changes to your fork

-   [Open a Pull Request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/) against the repository in the puppetlabs organization

## More about commits

1.  Make separate commits for logically separate changes.

    Please break your commits down into logically consistent units
    which include new or changed tests relevant to the rest of the
    change.  The goal of doing this is to make the diff easier to
    read for whoever is reviewing your code.  In general, the easier
    your diff is to read, the more likely someone will be happy to
    review it and get it into the code base.

    If you are going to refactor a piece of code, please do so as a
    separate commit from your feature or bug fix changes.

    We also really appreciate changes that include tests to make
    sure the bug is not re-introduced, and that the feature is not
    accidentally broken.

    Describe the technical detail of the change(s).  If your
    description starts to get too long, that is a good sign that you
    probably need to split up your commit into more finely grained
    pieces.

    Commits which plainly describe the things which help
    reviewers check the patch and future developers understand the
    code are much more likely to be merged in with a minimum of
    bike-shedding or requested changes.  Ideally, the commit message
    would include information, and be in a form suitable for
    inclusion in the release notes for the version of Puppet that
    includes them.

    Please also check that you are not introducing any trailing
    whitespace or other "whitespace errors".  You can do this by
    running "git diff --check" on your changes before you commit.

2.  Sending your patches

    To submit your changes via a GitHub pull request, we _highly_
    recommend that you have them on a topic branch, instead of
    directly on "master".
    It makes things much easier to keep track of, especially if
    you decide to work on another thing before your first change
    is merged in.

    GitHub has some pretty good
    [general documentation](http://help.github.com/) on using
    their site.  They also have documentation on
    [creating pull requests](https://help.github.com/articles/creating-a-pull-request-from-a-fork/).

    In general, after pushing your topic branch up to your
    repository on GitHub, you can switch to the branch in the
    GitHub UI and click "Pull Request" towards the top of the page
    in order to open a pull request.

# Generating Documentation

This repository uses [puppet-strings](https://puppet.com/docs/puppet/latest/puppet_strings.html) to generate the `reference.md` documentation for classes. Please ensure to document the classes as per the [puppet string style guide](https://puppet.com/docs/puppet/5.5/puppet_strings_style.html). The `REFERENCE.MD` can be generated with the following command.

```shell
% pdk bundle exec puppet strings generate --format markdown
```

# Testing

## Getting Started

Our Puppet modules use the [Puppet Development Kit (PDK)](https://puppet.com/docs/pdk/latest/pdk.html) for testing and validation. Please make sure you have [PDK installed](https://puppet.com/download-puppet-development-kit) on your system, and then use it to
install all dependencies needed for this project in the project root by running

```shell
% pdk validate
```

NOTE: some systems may require you to run this command with sudo.

## Running Tests

With all dependencies in place and up-to-date, run the tests:

### Validation Tests

```shell
% pdk validate
```

This executes all of the syntax and lint checks on the module. Please ensure that there are no issues with the syntax or formatting of your code prior to crearing a PR.

### Unit Tests

```shell
% pdk test unit
```

This executes all the [rspec tests](http://rspec-puppet.com/) in the directories defined [here](https://github.com/puppetlabs/puppetlabs_spec_helper/blob/699d9fbca1d2489bff1736bb254bb7b7edb32c74/lib/puppetlabs_spec_helper/rake_tasks.rb#L17) and so on.
rspec tests may have the same kind of dependencies as the module they are testing. Although the module defines these dependencies in its [metadata.json](./metadata.json),
rspec tests define them in [.fixtures.yml](./fixtures.yml).

### Acceptance Tests

This module comes with acceptance tests, which use [litmus](https://github.com/puppetlabs/puppet_litmus). These tests spin up containers under
[Docker](https://www.docker.com/) to simulate scripted test scenarios. In order to run these, you need Docker installed on your system.

Run the tests on EL nodes by issuing the following commands

```shell
% bundle install
% bundle exec rake 'litmus:provision_install[travis_el,puppet6]'
% bundle exec rake litmus:acceptance:parallel
% bundle exec rake litmus:tear_down
```

This will now download a CentOS 7 and a CentOS 6 containers configured in the [travis_el node-set](./provision.yaml),
install Puppet 6.x, copy this module, and install its dependencies per [spec/spec_helper_acceptance.rb](./spec/spec_helper_acceptance.rb)
and then run all the tests under [spec/acceptance](./spec/acceptance). Below will use Debian docker images to run the same tests.

```shell
% bundle install
% bundle exec rake 'litmus:provision_install[travis_deb,puppet6]'
% bundle exec rake litmus:acceptance:parallel
% bundle exec rake litmus:tear_down
```

## Writing Tests

### Unit Tests

When writing unit tests for Puppet, [rspec-puppet][https://rspec-puppet.com/) is your best friend. It provides tons of helper methods for testing your manifests against a
catalog (e.g. contain_file, contain_package, with_params, etc). It would be ridiculous to try and top rspec-puppet's [documentation](https://github.com/rodjek/rspec-puppet)
but here's a tiny sample:

Sample manifest:

```puppet
file { "a test file":
  ensure => present,
  path   => "/etc/sample",
}
```

Sample test:

```ruby
it 'does a thing' do
  expect(subject).to contain_file("a test file").with({:path => "/etc/sample"})
end
```

### Acceptance Tests

Writing acceptance tests for Puppet involves [litmus](https://github.com/puppetlabs/puppet_litmus) and [serverspec](https://serverspec.org/). A common pattern for acceptance tests is to create a test manifest, apply it
twice to check for idempotency or errors, then run expectations.

```ruby
it 'does an end-to-end thing' do
  pp = <<-EOF
    file { 'a test file':
      ensure  => present,
      path    => "/etc/sample",
      content => "test string",
    }

  apply_manifest(pp, :catch_failures => true)
  apply_manifest(pp, :catch_changes => true)

end

describe file("/etc/sample") do
  it { is_expected.to contain "test string" }
end
```

# If you have commit access to the repository

Even if you have commit access to the repository, you still need to go through the process above, and have someone else review and merge in your changes.  The rule is that **all changes must be reviewed by a project developer that did not write the code to ensure that all changes go through a code review process.**

The record of someone performing the merge is the record that they performed the code review. Again, this should be someone other than the author of the topic branch.

# Get Help

### On the web

-   [Puppet help messageboard](http://puppet.com/community/get-help)
-   [Writing tests](https://docs.puppet.com/guides/module_guides/bgtm.html#step-three-module-testing)
-   [General GitHub documentation](http://help.github.com/)
-   [GitHub pull request documentation](http://help.github.com/send-pull-requests/)

### On chat

-   Slack (slack.puppet.com) #forge-modules, #puppet-dev, #windows, #voxpupuli
-   IRC (freenode) #puppet-dev, #voxpupuli

[rspec-puppet]: http://rspec-puppet.com/

[rspec-puppet_docs]: http://rspec-puppet.com/documentation/
