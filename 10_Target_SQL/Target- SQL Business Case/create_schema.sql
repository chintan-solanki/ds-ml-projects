-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema target
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema target
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `target` DEFAULT CHARACTER SET utf8mb3;
USE `target` ;

-- -----------------------------------------------------
-- Table `target`.`geolocation`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `target`.`geolocation` ;

CREATE TABLE IF NOT EXISTS `target`.`geolocation` (
  `zip_code_prefix` INT NOT NULL,
  `lat` DECIMAL(24,20) NULL,
  `lng` DECIMAL(24,20) NULL,
  `city` VARCHAR(45) NULL,
  `state` VARCHAR(5) NULL)
ENGINE = InnoDB;


CREATE TABLE IF NOT EXISTS `target`.`customers` (
  `customer_id` CHAR(32) NOT NULL,
  `customer_unique_id` CHAR(32) NOT NULL,
  `zip_code_prefix` INT NULL DEFAULT NULL,
  `city` VARCHAR(45) NULL DEFAULT NULL,
  `state` VARCHAR(5) NULL DEFAULT NULL,
  PRIMARY KEY (`customer_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb3;

CREATE INDEX state_index ON `target`.`customers` (`state` ASC);
-- -----------------------------------------------------
-- Table `target`.`sellers`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `target`.`sellers` ;

CREATE TABLE IF NOT EXISTS `target`.`sellers` (
  `seller_id` CHAR(32) NOT NULL,
  `zip_code_prefix` INT NULL,
  `state` VARCHAR(5) NULL,
  `city` VARCHAR(45) NULL,
  PRIMARY KEY (`seller_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `target`.`products`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `target`.`products` ;

CREATE TABLE IF NOT EXISTS `target`.`products` (
  `product_id` CHAR(32) NOT NULL,
  `category` VARCHAR(100) NULL,
  `name_length` INT NULL,
  `description_length` INT NULL,
  `photos_qty` SMALLINT(255) NULL,
  `weight_g` INT NULL,
  `length_cm` INT NULL,
  `height_cm` INT NULL,
  `width_cm` INT NULL,
  PRIMARY KEY (`product_id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `target`.`orders`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `target`.`orders` ;

CREATE TABLE IF NOT EXISTS `target`.`orders` (
  `order_id` CHAR(32) NOT NULL,
  `customer_id` CHAR(32) NULL,
  `order_status` VARCHAR(45) NULL,
  `order_purchase_ts` DATETIME NULL,
  `order_approved_at` DATETIME NULL,
  `order_delivered_carrier_date` DATETIME NULL,
  `order_delivered_customer_date` DATETIME NULL,
  `order_estimated_delivery_date` DATETIME NULL,
  PRIMARY KEY (`order_id`),
  INDEX `cust_id_fk_idx` (`customer_id` ASC) VISIBLE,
  CONSTRAINT `orders_cust_id_fk`
    FOREIGN KEY (`customer_id`)
    REFERENCES `target`.`customers` (`customer_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `target`.`order_items`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `target`.`order_items` ;

CREATE TABLE IF NOT EXISTS `target`.`order_items` (
  `order_id` CHAR(32) NULL,
  `order_item_id` INT NULL,
  `product_id` CHAR(32) NULL,
  `seller_id` CHAR(32) NULL,
  `shipping_limit_date` DATETIME NULL,
  `price` DECIMAL(10,2) NULL,
  `freight_value` DECIMAL(10,2) NULL,
  INDEX `order_id_fk_idx` (`order_id` ASC) VISIBLE,
  INDEX `prod_id_fk_idx` (`product_id` ASC) VISIBLE,
  INDEX `seller_id_fk_idx` (`seller_id` ASC) VISIBLE,
  CONSTRAINT `order_items_order_id_fk`
    FOREIGN KEY (`order_id`)
    REFERENCES `target`.`orders` (`order_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `order_items_prod_id_fk`
    FOREIGN KEY (`product_id`)
    REFERENCES `target`.`products` (`product_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `order_items_seller_id_fk`
    FOREIGN KEY (`seller_id`)
    REFERENCES `target`.`sellers` (`seller_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `target`.`order_payment`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `target`.`order_payment` ;

CREATE TABLE IF NOT EXISTS `target`.`order_payment` (
  `order_id` CHAR(32) NULL,
  `payment_sequential` INT NULL,
  `payment_type` VARCHAR(45) NULL,
  `payment_installment` INT NULL,
  `payment_value` DECIMAL(10,2) NULL,
  `order_paymentcol` VARCHAR(45) NULL,
  INDEX `order_id_fk_idx` (`order_id` ASC) VISIBLE,
  CONSTRAINT `payments_order_id_fk`
    FOREIGN KEY (`order_id`)
    REFERENCES `target`.`orders` (`order_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `target`.`order_reviews`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `target`.`order_reviews` ;

CREATE TABLE IF NOT EXISTS `target`.`order_reviews` (
  `review_id` CHAR(32) NOT NULL,
  `order_id` CHAR(32) NOT NULL,
  `review_score` TINYINT NULL,
  `review_comment_title` VARCHAR(255) NULL,
  `review_creation_date` DATETIME NULL,
  `review_answer_timestamp` DATETIME NULL,
  INDEX `order_id_fk_idx` (`order_id` ASC) INVISIBLE,
  UNIQUE INDEX `reviews_unique_key` (`review_id` ASC, `order_id` ASC) VISIBLE,
  CONSTRAINT `reviews_order_id_fk`
    FOREIGN KEY (`order_id`)
    REFERENCES `target`.`orders` (`order_id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
