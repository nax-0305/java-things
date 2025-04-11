CREATE TABLE `process_definition` (
    `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
    `name` VARCHAR(100) NOT NULL COMMENT '流程名称',
    `key` VARCHAR(50) NOT NULL COMMENT '唯一标识（如LEAVE）',
    `version` INT NOT NULL COMMENT '版本号（乐观锁）',
    `status` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '0-停用 1-启用',
    `node_config` JSON NOT NULL COMMENT '节点配置（支持角色/部门/表达式）',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_key_version` (`key`, `version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试数据
INSERT INTO `process_definition` VALUES
 ('def-001', '员工请假流程', 'LEAVE', 1, 1,
  '{
    "nodes": [
      {"id":"start","type":"start","outgoing":["dept_approve"]},
      {"id":"dept_approve","type":"userTask",
        "assignRules":[
          {"type":"dept_leader","priority":1},
          {"type":"role","value":"backup_leader","priority":2}
        ],"outgoing":["end"]},
      {"id":"end","type":"end"}
    ]
  }', NOW(), NOW()),

 ('def-002', '费用报销流程', 'REIMBURSE', 1, 1,
  '{
    "nodes": [
      {"id":"start","type":"start","outgoing":["finance_approve"]},
      {"id":"finance_approve","type":"userTask",
        "assignRules":[
          {"type":"role","value":"finance_mgr","priority":1},
          {"type":"expression","value":"$applicant.dept.leader","priority":2}
        ],"outgoing":["end"]},
      {"id":"end","type":"end"}
    ]
  }', NOW(), NOW()
);

CREATE TABLE `process_instance` (
    `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
    `def_id` VARCHAR(36) NOT NULL COMMENT '流程定义ID',
    `business_key` VARCHAR(50) NOT NULL COMMENT '业务单据号（唯一）',
    `current_node` VARCHAR(50) NOT NULL COMMENT '当前节点ID',
    `status` ENUM('RUNNING','COMPLETED','TERMINATED') DEFAULT 'RUNNING',
    `variables` JSON NOT NULL COMMENT '流程变量',
    `start_user_id` VARCHAR(36) NOT NULL COMMENT '发起人',
    `start_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `end_time` DATETIME DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_business_key` (`business_key`),
    KEY `idx_def_status` (`def_id`,`status`),
    FOREIGN KEY (`def_id`) REFERENCES `process_definition`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试数据
INSERT INTO `process_instance` VALUES
('inst-001', 'def-001', 'LEAVE-20231101', 'dept_approve', 'RUNNING',
'{"applicant":"user-001", "days":3, "reason":"病假"}', 'user-001', NOW(), NULL),

('inst-002', 'def-002', 'REIMB-20231101', 'finance_approve', 'RUNNING',
'{"amount":5000, "type":"差旅费", "applicant_dept":"dept-001"}', 'user-002', NOW(), NULL);



CREATE TABLE `approval_task` (
    `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
    `instance_id` VARCHAR(36) NOT NULL,
    `node_id` VARCHAR(50) NOT NULL,
    `assignee` VARCHAR(36) DEFAULT NULL COMMENT '当前处理人',
    `candidates` JSON NOT NULL COMMENT '候选处理人列表',
    `task_type` ENUM('NORMAL','COUNTERSIGN') DEFAULT 'NORMAL',
    `status` ENUM('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_instance_node` (`instance_id`,`node_id`),
    KEY `idx_assignee_status` (`assignee`,`status`),
    FOREIGN KEY (`instance_id`) REFERENCES `process_instance`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试数据
INSERT INTO `approval_task` VALUES
('task-001', 'inst-001', 'dept_approve', 'mgr-001',
 '["mgr-001", "mgr-002"]', 'NORMAL', 'PENDING', NOW(), NOW()),

('task-002', 'inst-002', 'finance_approve', 'fina-001',
 '["fina-001", "fina-002"]', 'COUNTERSIGN', 'PENDING', NOW(), NOW());


CREATE TABLE `sys_dept` (
    `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
    `name` VARCHAR(50) NOT NULL,
    `parent_id` VARCHAR(36) DEFAULT NULL COMMENT '上级部门',
    `leader_id` VARCHAR(36) DEFAULT NULL COMMENT '部门负责人',
    PRIMARY KEY (`id`),
    KEY `idx_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `sys_dept` VALUES
('dept-001', '技术部', NULL, 'mgr-001'),
('dept-002', '财务部', NULL, 'fina-001');

CREATE TABLE `sys_user` (
    `id` VARCHAR(36) NOT NULL COMMENT 'UUID主键',
    `username` VARCHAR(50) NOT NULL,
    `realname` VARCHAR(50) NOT NULL,
    `dept_id` VARCHAR(36) NOT NULL,
    `email` VARCHAR(100) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    FOREIGN KEY (`dept_id`) REFERENCES `sys_dept`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `sys_user` VALUES
('user-001', 'zhangsan', '张三', 'dept-001', 'zhangsan@example.com'),
('mgr-001', 'wangwu', '王五', 'dept-001', 'wangwu@example.com'),
('fina-001', 'zhaoliu', '赵六', 'dept-002', 'zhaoliu@example.com');

CREATE TABLE `sys_role` (
    `code` VARCHAR(50) NOT NULL COMMENT '角色编码',
    `name` VARCHAR(50) NOT NULL COMMENT '角色名称',
    `description` VARCHAR(200) DEFAULT NULL,
    PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `sys_role` VALUES
   ('dept_leader', '部门主管', '部门负责人'),
   ('finance_mgr', '财务经理', '财务审批权限'),
   ('backup_leader', '后备主管', '部门主管代理人');

CREATE TABLE `sys_user_role` (
     `user_id` VARCHAR(36) NOT NULL,
     `role_code` VARCHAR(50) NOT NULL,
     PRIMARY KEY (`user_id`, `role_code`),
     FOREIGN KEY (`user_id`) REFERENCES `sys_user`(`id`),
     FOREIGN KEY (`role_code`) REFERENCES `sys_role`(`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `sys_user_role` VALUES
('mgr-001', 'dept_leader'),
('fina-001', 'finance_mgr'),
('mgr-001', 'backup_leader');


CREATE TABLE `approval_history` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `task_id` VARCHAR(36) NOT NULL,
    `action` ENUM('SUBMIT','APPROVE','REJECT','TRANSFER') NOT NULL,
    `comment` VARCHAR(500) DEFAULT NULL,
    `operator` VARCHAR(36) NOT NULL,
    `operate_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_task` (`task_id`),
    FOREIGN KEY (`task_id`) REFERENCES `approval_task`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `approval_history` VALUES
    (NULL, 'task-001', 'APPROVE', '同意申请', 'mgr-001', NOW());

CREATE TABLE `task_countersign` (
    `task_id` VARCHAR(36) NOT NULL COMMENT '主任务ID',
    `required_num` INT NOT NULL COMMENT '需同意人数',
    `approved_num` INT NOT NULL DEFAULT 0,
    `rejected_num` INT NOT NULL DEFAULT 0,
    `strategy` ENUM('ALL','ANY','PERCENTAGE') NOT NULL DEFAULT 'ALL' COMMENT '通过策略',
    `threshold` DECIMAL(5,2) DEFAULT 100.00 COMMENT '通过阈值（百分比）',
    PRIMARY KEY (`task_id`),
    CONSTRAINT `fk_countersign_task` FOREIGN KEY (`task_id`) REFERENCES `approval_task` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='会签任务扩展表';
