AnacapaJenkinsAPI.configure(YAML.load_file("./jenkins.yml"))

class HandlePushJob < ApplicationJob
  queue_as :default
  include AssignmentsHelper

  def perform(push)
    assign_repos = assignment_repos

    repo = push['repository']['name']
    url = push['repository']['url']
    commit = push['after']

    logger.warn "Received push event webhook for repo: #{repo} (commit #{commit})"
    logger.warn "Repo url: #{url}"
    logger.warn "is assignment repo? #{is_assignment? repo}"
    logger.warn "is student repo? #{is_student_repo? assign_repos, repo}"
    # logger.warn JSON.pretty_generate(push)

    if is_assignment? repo
      assignment = AnacapaJenkinsAPI::Assignment.new(
        :callback_url => '',
        :git_provider_domain => ENV['GIT_PROVIDER_URL'],
        :course_org => ENV['COURSE_ORGANIZATION'],
        :credentials_id => ENV['JENKINS_MACHINE_USER_CREDENTIALS_ID'],
        :lab_name => repo[('assignment-'.length) .. -1]
      )

      begin
        assignment.check_jenkins_state
        build = assignment.job_instructor.rebuild
      rescue Exception => e
        logger.error("Error processing webhook: #{e.message}")
      end

    elsif is_student_repo? assign_repos, repo
      assign_repo, students = student_repo_get_assignment(assign_repos, repo)

      assignment = AnacapaJenkinsAPI::Assignment.new(
        :callback_url => '',
        :git_provider_domain => ENV['GIT_PROVIDER_URL'],
        :course_org => ENV['COURSE_ORGANIZATION'],
        :credentials_id => ENV['JENKINS_MACHINE_USER_CREDENTIALS_ID'],
        :lab_name => assign_repo.name[('assignment-'.length) .. -1]
      )

      begin
        assignment.check_jenkins_state
        build = assignment.job_grader.rebuild({
          github_user: students,
          commit: push['after']
        })
      rescue Exception => e
        logger.error("Error processing webhook: #{e.message}")
      end
    else
      logger.warn "Push notification corresponds to neither a student repo nor an instructor repo"
    end
  end

end
