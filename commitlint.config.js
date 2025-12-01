export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Enforce conventional commit types
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation
        'style',    // Code style (formatting, etc.)
        'refactor', // Code refactoring
        'perf',     // Performance improvement
        'test',     // Tests
        'chore',    // Maintenance
        'ci',       // CI/CD changes
        'build',    // Build system
        'revert',   // Revert commits
      ],
    ],
    // Allow any scope (project-specific)
    'scope-enum': [0],
    // Reasonable subject length
    'subject-max-length': [2, 'always', 100],
    // Body and footer can be longer
    'body-max-line-length': [0],
    'footer-max-line-length': [0],
  },
};
